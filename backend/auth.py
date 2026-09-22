import os
import hashlib
import secrets
import json
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

from dotenv import load_dotenv
import psycopg
from psycopg.rows import dict_row

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel, EmailStr


# ============================================================
# ENVIRONMENT
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

load_dotenv(BASE_DIR / '.env')


DATABASE_URL = os.getenv(
    'SUPABASE_DATABASE_URL',
    ''
).strip()


if not DATABASE_URL:
    raise RuntimeError(
        'SUPABASE_DATABASE_URL is not configured.'
    )


# ============================================================
# JWT / PASSWORD SETTINGS
# ============================================================

JWT_SECRET = os.getenv(
    'BIS_SAATHI_JWT_SECRET',
    'CHANGE_THIS_SECRET_BEFORE_PRODUCTION'
)

JWT_ALGORITHM = 'HS256'

ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24

PASSWORD_ITERATIONS = 310000

RESEND_API_KEY = os.getenv(
    'RESEND_API_KEY',
    ''
).strip()

RESEND_FROM_EMAIL = os.getenv(
    'RESEND_FROM_EMAIL',
    'onboarding@resend.dev'
).strip()

PASSWORD_RESET_MINUTES = int(
    os.getenv(
        'BIS_SAATHI_PASSWORD_RESET_MINUTES',
        '10'
    )
)


# ============================================================
# ROUTER / SECURITY
# ============================================================

router = APIRouter(
    prefix='/api/auth',
    tags=['Authentication']
)

security = HTTPBearer(auto_error=False)


# ============================================================
# POSTGRESQL CONNECTION
# ============================================================

def get_connection():
    connection = psycopg.connect(
        DATABASE_URL,
        connect_timeout=10,
        row_factory=dict_row
    )

    return connection


# ============================================================
# DATABASE INITIALIZATION
# ============================================================

def init_database():
    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id BIGSERIAL PRIMARY KEY,
                    full_name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    password_salt TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'user',
                    preferred_language TEXT NOT NULL DEFAULT 'English',
                    is_active BOOLEAN NOT NULL DEFAULT TRUE,
                    created_at TEXT NOT NULL,
                    last_login TEXT
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS user_activity (
                    id BIGSERIAL PRIMARY KEY,
                    user_id BIGINT NOT NULL,
                    activity_type TEXT NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id)
                        REFERENCES users(id)
                        ON DELETE CASCADE
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS conversations (
                    id BIGSERIAL PRIMARY KEY,
                    user_id BIGINT NOT NULL,
                    title TEXT NOT NULL DEFAULT 'New Conversation',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    FOREIGN KEY (user_id)
                        REFERENCES users(id)
                        ON DELETE CASCADE
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS conversation_messages (
                    id BIGSERIAL PRIMARY KEY,
                    conversation_id BIGINT NOT NULL,
                    user_id BIGINT NOT NULL,
                    question TEXT NOT NULL,
                    answer TEXT NOT NULL,
                    sources_json TEXT NOT NULL DEFAULT '[]',
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (conversation_id)
                        REFERENCES conversations(id)
                        ON DELETE CASCADE,
                    FOREIGN KEY (user_id)
                        REFERENCES users(id)
                        ON DELETE CASCADE
                )
            """)

            cursor.execute("""
                CREATE TABLE IF NOT EXISTS password_reset_tokens (
                    id BIGSERIAL PRIMARY KEY,
                    user_id BIGINT NOT NULL,
                    code_hash TEXT NOT NULL,
                    expires_at TEXT NOT NULL,
                    used BOOLEAN NOT NULL DEFAULT FALSE,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
                )
            """)

            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_password_reset_user
                ON password_reset_tokens(user_id)
            """)

            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_conversations_user
                ON conversations(user_id)
            """)

            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_messages_conversation
                ON conversation_messages(conversation_id)
            """)

            cursor.execute("""
                CREATE INDEX IF NOT EXISTS idx_messages_user
                ON conversation_messages(user_id)
            """)

        connection.commit()

    finally:
        connection.close()


init_database()


# ============================================================
# PASSWORD FUNCTIONS
# ============================================================

def hash_password(
    password: str,
    salt: str | None = None
):
    if salt is None:
        salt = secrets.token_hex(16)

    derived_key = hashlib.pbkdf2_hmac(
        'sha256',
        password.encode('utf-8'),
        salt.encode('utf-8'),
        PASSWORD_ITERATIONS
    )

    password_hash = derived_key.hex()

    return password_hash, salt


def verify_password(
    password: str,
    stored_hash: str,
    stored_salt: str
):
    calculated_hash, _ = hash_password(
        password,
        stored_salt
    )

    return secrets.compare_digest(
        calculated_hash,
        stored_hash
    )


# ============================================================
# PASSWORD RESET EMAIL
# ============================================================

def _send_password_reset_email(
    email: str,
    full_name: str,
    code: str
):
    if not RESEND_API_KEY:
        raise HTTPException(
            status_code=503,
            detail=(
                'Password reset email service is not configured. '
                'Please configure RESEND_API_KEY.'
            )
        )

    payload = {
        'from': RESEND_FROM_EMAIL,
        'to': [email],
        'subject': 'BIS Saathi Password Reset Code',
        'text': f"""Hello {full_name},

Your BIS Saathi password reset code is:

{code}

This code expires in {PASSWORD_RESET_MINUTES} minutes.

If you did not request a password reset, you can safely ignore this email.

BIS Saathi
"""
    }

    try:
        from urllib.request import Request, urlopen
        from urllib.error import HTTPError

        request = Request(
            'https://api.resend.com/emails',
            data=json.dumps(payload).encode('utf-8'),
            headers={
                'Authorization': f'Bearer {RESEND_API_KEY}',
                'Content-Type': 'application/json'
            },
            method='POST'
        )

        with urlopen(request, timeout=15) as response:
            response.read()

            if response.status < 200 or response.status >= 300:
                raise RuntimeError(
                    f'Resend returned HTTP {response.status}'
                )

    except HTTPError as exc:
        try:
            error_body = exc.read().decode(
                'utf-8',
                errors='replace'
            )
        except Exception:
            error_body = ''

        print(
            'Resend email error:',
            exc.code,
            error_body
        )

        raise HTTPException(
            status_code=503,
            detail=(
                'Unable to send the password reset email '
                'right now. Please try again later.'
            )
        )

    except Exception as exc:
        print(
            'Password reset email error:',
            repr(exc)
        )

        raise HTTPException(
            status_code=503,
            detail=(
                'Unable to send the password reset email '
                'right now. Please try again later.'
            )
        )


# ============================================================
# JWT
# ============================================================

def create_access_token(
    user_id: int,
    role: str
):
    now = datetime.now(timezone.utc)

    expires = now + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES
    )

    payload = {
        'sub': str(user_id),
        'role': role,
        'iat': int(now.timestamp()),
        'exp': int(expires.timestamp())
    }

    return jwt.encode(
        payload,
        JWT_SECRET,
        algorithm=JWT_ALGORITHM
    )


# ============================================================
# CURRENT USER
# ============================================================

def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        security
    )
):
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Authentication required.'
        )

    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM]
        )

        user_id = payload.get('sub')

        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail='Invalid authentication token.'
            )

        user_id_int = int(user_id)

    except (
        JWTError,
        ValueError,
        TypeError
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='Invalid or expired authentication token.'
        )

    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    full_name,
                    email,
                    password_hash,
                    password_salt,
                    role,
                    preferred_language,
                    is_active,
                    created_at,
                    last_login
                FROM users
                WHERE id=%s
            """, (user_id_int,))

            user = cursor.fetchone()

    finally:
        connection.close()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail='User account not found.'
        )

    if not user['is_active']:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='This user account is inactive.'
        )

    return user


def get_current_admin(
    current_user=Depends(get_current_user)
):
    if current_user['role'] != 'admin':
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail='Administrator access required.'
        )

    return current_user


# ============================================================
# ACTIVITY
# ============================================================

ALLOWED_ACTIVITY_TYPES = {
    'chat',
    'standard_view',
    'compliance_check',
    'document_upload',
    'document_question',
    'service_view'
}


def record_activity(
    user_id: int,
    activity_type: str
):
    if activity_type not in ALLOWED_ACTIVITY_TYPES:
        return False

    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO user_activity (
                    user_id,
                    activity_type,
                    created_at
                )
                VALUES (%s, %s, %s)
            """, (
                user_id,
                activity_type,
                datetime.now(timezone.utc).isoformat()
            ))

        connection.commit()

    finally:
        connection.close()

    return True


def get_activity_summary(
    user_id: int
):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    activity_type,
                    COUNT(*) AS total
                FROM user_activity
                WHERE user_id=%s
                GROUP BY activity_type
            """, (user_id,))

            rows = cursor.fetchall()

    finally:
        connection.close()

    counts = {
        'chat': 0,
        'standard_view': 0,
        'compliance_check': 0,
        'document_upload': 0,
        'document_question': 0,
        'service_view': 0
    }

    for row in rows:
        activity_type = row['activity_type']

        if activity_type in counts:
            counts[activity_type] = row['total']

    return counts


def get_admin_dashboard_stats():
    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute("""
                SELECT COUNT(*)
                FROM users
            """)
            total_users = cursor.fetchone()['count']

            cursor.execute("""
                SELECT COUNT(*)
                FROM users
                WHERE is_active=TRUE
            """)
            active_users = cursor.fetchone()['count']

            cursor.execute("""
                SELECT COUNT(*)
                FROM users
                WHERE is_active=FALSE
            """)
            inactive_users = cursor.fetchone()['count']

            cursor.execute("""
                SELECT COUNT(*)
                FROM users
                WHERE role='admin'
            """)
            admin_users = cursor.fetchone()['count']

            cursor.execute("""
                SELECT COUNT(*)
                FROM users
                WHERE role='user'
            """)
            normal_users = cursor.fetchone()['count']

            cursor.execute("""
                SELECT
                    activity_type,
                    COUNT(*) AS total
                FROM user_activity
                GROUP BY activity_type
            """)

            activity_rows = cursor.fetchall()

    finally:
        connection.close()

    activity = {
        'chat': 0,
        'standard_view': 0,
        'compliance_check': 0,
        'document_upload': 0,
        'document_question': 0,
        'service_view': 0
    }

    for row in activity_rows:
        activity_type = row['activity_type']

        if activity_type in activity:
            activity[activity_type] = row['total']

    return {
        'totalUsers': total_users,
        'activeUsers': active_users,
        'inactiveUsers': inactive_users,
        'adminUsers': admin_users,
        'normalUsers': normal_users,
        'aiQuestions': activity['chat'],
        'standardsViewed': activity['standard_view'],
        'complianceChecks': activity['compliance_check'],
        'documentUploads': activity['document_upload'],
        'documentQuestions': activity['document_question'],
        'documents': (
            activity['document_upload']
            + activity['document_question']
        ),
        'servicesViewed': activity['service_view']
    }


def get_user_activity_details(
    user_id: int
):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    activity_type,
                    created_at
                FROM user_activity
                WHERE user_id=%s
                ORDER BY id DESC
                LIMIT 100
            """, (user_id,))

            rows = cursor.fetchall()

    finally:
        connection.close()

    activities = []

    for row in rows:
        activities.append({
            'id': row['id'],
            'activityType': row['activity_type'],
            'createdAt': row['created_at']
        })

    return activities


# ============================================================
# REQUEST MODELS
# ============================================================

class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    preferred_language: str = 'English'


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    email: EmailStr
    code: str
    new_password: str


class ActivityRequest(BaseModel):
    activity_type: str


class AdminUserUpdateRequest(BaseModel):
    is_active: Optional[bool] = None
    role: Optional[str] = None


class AdminRecoveryRequest(BaseModel):
    email: EmailStr
    password: str
    recovery_key: str
    full_name: str = 'BIS Saathi Administrator'
    preferred_language: str = 'English'


class ConversationCreateRequest(BaseModel):
    title: str = 'New Conversation'


class ConversationMessageRequest(BaseModel):
    question: str
    answer: str
    sources: list[str] = []


# ============================================================
# REGISTER
# ============================================================

@router.post('/register')
def register(
    request: RegisterRequest
):
    full_name = request.full_name.strip()
    email = str(request.email).strip().lower()
    password = request.password

    if len(full_name) < 2:
        raise HTTPException(
            status_code=400,
            detail='Please enter your full name.'
        )

    if len(password) < 8:
        raise HTTPException(
            status_code=400,
            detail='Password must contain at least 8 characters.'
        )

    allowed_languages = {
        'English',
        'Hindi',
        'Marathi'
    }

    preferred_language = request.preferred_language

    if preferred_language not in allowed_languages:
        preferred_language = 'English'

    password_hash, password_salt = hash_password(
        password
    )

    created_at = datetime.now(
        timezone.utc
    ).isoformat()

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute("""
                SELECT id
                FROM users
                WHERE email=%s
            """, (email,))

            existing_user = cursor.fetchone()

            if existing_user is not None:
                raise HTTPException(
                    status_code=409,
                    detail='An account with this email already exists.'
                )

            cursor.execute("""
                INSERT INTO users (
                    full_name,
                    email,
                    password_hash,
                    password_salt,
                    role,
                    preferred_language,
                    is_active,
                    created_at
                )
                VALUES (
                    %s, %s, %s, %s,
                    %s, %s, %s, %s
                )
                RETURNING id
            """, (
                full_name,
                email,
                password_hash,
                password_salt,
                'user',
                preferred_language,
                True,
                created_at
            ))

            user_id = cursor.fetchone()['id']

        connection.commit()

    finally:
        connection.close()

    token = create_access_token(
        user_id,
        'user'
    )

    return {
        'success': True,
        'message': 'Account created successfully.',
        'accessToken': token,
        'user': {
            'id': user_id,
            'fullName': full_name,
            'email': email,
            'role': 'user',
            'preferredLanguage': preferred_language
        }
    }


# ============================================================
# LOGIN
# ============================================================

@router.post('/login')
def login(
    request: LoginRequest
):
    email = str(
        request.email
    ).strip().lower()

    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT *
                FROM users
                WHERE email=%s
            """, (email,))

            user = cursor.fetchone()

            if user is None:
                raise HTTPException(
                    status_code=401,
                    detail='Invalid email or password.'
                )

            if not user['is_active']:
                raise HTTPException(
                    status_code=403,
                    detail='This account is inactive.'
                )

            valid_password = verify_password(
                request.password,
                user['password_hash'],
                user['password_salt']
            )

            if not valid_password:
                raise HTTPException(
                    status_code=401,
                    detail='Invalid email or password.'
                )

            last_login = datetime.now(
                timezone.utc
            ).isoformat()

            cursor.execute("""
                UPDATE users
                SET last_login=%s
                WHERE id=%s
            """, (
                last_login,
                user['id']
            ))

        connection.commit()

    finally:
        connection.close()

    token = create_access_token(
        user['id'],
        user['role']
    )

    return {
        'success': True,
        'message': 'Login successful.',
        'accessToken': token,
        'user': {
            'id': user['id'],
            'fullName': user['full_name'],
            'email': user['email'],
            'role': user['role'],
            'preferredLanguage': user['preferred_language']
        }
    }


# ============================================================
# CHANGE PASSWORD
# ============================================================

@router.post('/change-password')
def change_password(request: ChangePasswordRequest, current_user=Depends(get_current_user)):
    if len(request.new_password) < 8:
        raise HTTPException(status_code=400, detail='New password must contain at least 8 characters.')
    if request.current_password == request.new_password:
        raise HTTPException(status_code=400, detail='New password must be different from your current password.')
    if not verify_password(request.current_password, current_user['password_hash'], current_user['password_salt']):
        raise HTTPException(status_code=401, detail='Current password is incorrect.')
    password_hash, password_salt = hash_password(request.new_password)
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("UPDATE users SET password_hash=%s, password_salt=%s WHERE id=%s", (password_hash, password_salt, current_user['id']))
        connection.commit()
    finally:
        connection.close()
    return {'success': True, 'message': 'Password changed successfully.'}


# ============================================================
# FORGOT PASSWORD
# ============================================================

@router.post('/forgot-password')
def forgot_password(request: ForgotPasswordRequest):
    email = str(request.email).strip().lower()
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT id, full_name, email, is_active FROM users WHERE email=%s", (email,))
            user = cursor.fetchone()
            if user is not None:
                cursor.execute("UPDATE password_reset_tokens SET used=TRUE WHERE user_id=%s AND used=FALSE", (user['id'],))
        connection.commit()
    finally:
        connection.close()
    if user is None or not user['is_active']:
        return {'success': True, 'message': 'If an active account exists for this email, a reset code has been sent.'}
    code = f'{secrets.randbelow(1000000):06d}'
    code_hash = hashlib.sha256(code.encode('utf-8')).hexdigest()
    now = datetime.now(timezone.utc)
    expires_at = now + timedelta(minutes=PASSWORD_RESET_MINUTES)
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("INSERT INTO password_reset_tokens (user_id, code_hash, expires_at, used, created_at) VALUES (%s, %s, %s, FALSE, %s)", (user['id'], code_hash, expires_at.isoformat(), now.isoformat()))
        connection.commit()
    finally:
        connection.close()
    _send_password_reset_email(user['email'], user['full_name'], code)
    return {'success': True, 'message': 'If an active account exists for this email, a reset code has been sent.'}


# ============================================================
# RESET PASSWORD
# ============================================================

@router.post('/reset-password')
def reset_password(request: ResetPasswordRequest):
    email = str(request.email).strip().lower()
    code = request.code.strip()
    if len(request.new_password) < 8:
        raise HTTPException(status_code=400, detail='New password must contain at least 8 characters.')
    if len(code) != 6 or not code.isdigit():
        raise HTTPException(status_code=400, detail='Please enter the valid 6-digit verification code.')
    code_hash = hashlib.sha256(code.encode('utf-8')).hexdigest()
    now = datetime.now(timezone.utc)
    connection = get_connection()
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT r.id, r.user_id, r.code_hash, r.expires_at, r.used FROM password_reset_tokens r JOIN users u ON u.id=r.user_id WHERE u.email=%s ORDER BY r.id DESC LIMIT 1", (email,))
            record = cursor.fetchone()
            if record is None or record['used']:
                raise HTTPException(status_code=400, detail='Invalid or expired password reset code.')
            try:
                expires_at = datetime.fromisoformat(record['expires_at'])
            except Exception:
                expires_at = now - timedelta(seconds=1)
            if expires_at <= now or not secrets.compare_digest(code_hash, record['code_hash']):
                raise HTTPException(status_code=400, detail='Invalid or expired password reset code.')
            password_hash, password_salt = hash_password(request.new_password)
            cursor.execute("UPDATE users SET password_hash=%s, password_salt=%s WHERE id=%s", (password_hash, password_salt, record['user_id']))
            cursor.execute("UPDATE password_reset_tokens SET used=TRUE WHERE id=%s", (record['id'],))
        connection.commit()
    finally:
        connection.close()
    return {'success': True, 'message': 'Password reset successfully.'}


# ============================================================
# ADMIN RECOVERY
# ============================================================

@router.post('/admin/recover')
def recover_admin_account(
    request: AdminRecoveryRequest
):
    recovery_key = os.getenv(
        'BIS_SAATHI_ADMIN_RECOVERY_KEY',
        ''
    ).strip()

    if not recovery_key:
        raise HTTPException(
            status_code=503,
            detail='Administrator recovery is not enabled.'
        )

    if not secrets.compare_digest(
        request.recovery_key,
        recovery_key
    ):
        raise HTTPException(
            status_code=403,
            detail='Invalid administrator recovery key.'
        )

    password = request.password

    if len(password) < 8:
        raise HTTPException(
            status_code=400,
            detail='Password must contain at least 8 characters.'
        )

    email = str(
        request.email
    ).strip().lower()

    full_name = (
        request.full_name.strip()
        or 'BIS Saathi Administrator'
    )

    if len(full_name) < 2:
        full_name = 'BIS Saathi Administrator'

    allowed_languages = {
        'English',
        'Hindi',
        'Marathi'
    }

    preferred_language = request.preferred_language

    if preferred_language not in allowed_languages:
        preferred_language = 'English'

    password_hash, password_salt = hash_password(
        password
    )

    now = datetime.now(
        timezone.utc
    ).isoformat()

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute("""
                UPDATE users
                SET role='user'
                WHERE role='admin'
                AND email<>%s
            """, (email,))

            cursor.execute("""
                SELECT id
                FROM users
                WHERE email=%s
            """, (email,))

            existing_user = cursor.fetchone()

            if existing_user is not None:

                cursor.execute("""
                    UPDATE users
                    SET
                        full_name=%s,
                        password_hash=%s,
                        password_salt=%s,
                        role='admin',
                        preferred_language=%s,
                        is_active=TRUE
                    WHERE id=%s
                """, (
                    full_name,
                    password_hash,
                    password_salt,
                    preferred_language,
                    existing_user['id']
                ))

                user_id = existing_user['id']

                message = (
                    'Administrator account recovered successfully.'
                )

            else:

                cursor.execute("""
                    INSERT INTO users (
                        full_name,
                        email,
                        password_hash,
                        password_salt,
                        role,
                        preferred_language,
                        is_active,
                        created_at
                    )
                    VALUES (
                        %s, %s, %s, %s,
                        'admin', %s, TRUE, %s
                    )
                    RETURNING id
                """, (
                    full_name,
                    email,
                    password_hash,
                    password_salt,
                    preferred_language,
                    now
                ))

                user_id = cursor.fetchone()['id']

                message = (
                    'Administrator account created successfully.'
                )

        connection.commit()

    finally:
        connection.close()

    return {
        'success': True,
        'message': message,
        'user': {
            'id': user_id,
            'fullName': full_name,
            'email': email,
            'role': 'admin',
            'preferredLanguage': preferred_language,
            'isActive': True
        }
    }


# ============================================================
# ME
# ============================================================

@router.get('/me')
def me(
    current_user=Depends(get_current_user)
):
    return {
        'success': True,
        'user': {
            'id': current_user['id'],
            'fullName': current_user['full_name'],
            'email': current_user['email'],
            'role': current_user['role'],
            'preferredLanguage': current_user['preferred_language'],
            'isActive': bool(
                current_user['is_active']
            ),
            'createdAt': current_user['created_at'],
            'lastLogin': current_user['last_login']
        }
    }


# ============================================================
# USER ACTIVITY
# ============================================================

@router.get('/activity')
def activity(
    current_user=Depends(get_current_user)
):
    counts = get_activity_summary(
        current_user['id']
    )

    return {
        'success': True,
        'activity': {
            'aiQuestions': counts['chat'],
            'standardsViewed': counts['standard_view'],
            'complianceChecks': counts['compliance_check'],
            'documents': (
                counts['document_upload']
                + counts['document_question']
            ),
            'documentUploads': counts['document_upload'],
            'documentQuestions': counts['document_question'],
            'servicesViewed': counts['service_view']
        }
    }


@router.post('/activity')
def create_activity(
    request: ActivityRequest,
    current_user=Depends(get_current_user)
):
    success = record_activity(
        current_user['id'],
        request.activity_type
    )

    if not success:
        raise HTTPException(
            status_code=400,
            detail=(
                'Unsupported activity type. '
                'Use chat, standard_view, '
                'compliance_check, document_upload, '
                'document_question or service_view.'
            )
        )

    return {
        'success': True,
        'message': 'Activity recorded.'
    }


# ============================================================
# CONVERSATIONS
# ============================================================

def create_conversation_for_user(
    user_id: int,
    title: str = 'New Conversation'
):
    now = datetime.now(
        timezone.utc
    ).isoformat()

    clean_title = title.strip()

    if not clean_title:
        clean_title = 'New Conversation'

    if len(clean_title) > 120:
        clean_title = clean_title[:120]

    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO conversations (
                    user_id,
                    title,
                    created_at,
                    updated_at
                )
                VALUES (%s, %s, %s, %s)
                RETURNING id
            """, (
                user_id,
                clean_title,
                now,
                now
            ))

            conversation_id = cursor.fetchone()['id']

        connection.commit()

    finally:
        connection.close()

    return {
        'id': conversation_id,
        'title': clean_title,
        'createdAt': now,
        'updatedAt': now,
        'messageCount': 0
    }


def get_user_conversation(
    user_id: int,
    conversation_id: int
):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    user_id,
                    title,
                    created_at,
                    updated_at
                FROM conversations
                WHERE id=%s
                AND user_id=%s
            """, (
                conversation_id,
                user_id
            ))

            conversation = cursor.fetchone()

    finally:
        connection.close()

    return conversation


@router.get('/conversations')
def list_conversations(
    current_user=Depends(get_current_user)
):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    c.id,
                    c.title,
                    c.created_at,
                    c.updated_at,
                    COUNT(m.id) AS message_count
                FROM conversations c
                LEFT JOIN conversation_messages m
                    ON m.conversation_id=c.id
                WHERE c.user_id=%s
                GROUP BY
                    c.id,
                    c.title,
                    c.created_at,
                    c.updated_at
                ORDER BY c.updated_at DESC
            """, (
                current_user['id'],
            ))

            rows = cursor.fetchall()

    finally:
        connection.close()

    conversations = []

    for row in rows:
        conversations.append({
            'id': row['id'],
            'title': row['title'],
            'createdAt': row['created_at'],
            'updatedAt': row['updated_at'],
            'messageCount': row['message_count']
        })

    return {
        'success': True,
        'conversations': conversations
    }


@router.post('/conversations')
def create_conversation(
    request: ConversationCreateRequest,
    current_user=Depends(get_current_user)
):
    conversation = create_conversation_for_user(
        current_user['id'],
        request.title
    )

    return {
        'success': True,
        'conversation': conversation
    }


@router.get(
    '/conversations/{conversation_id}'
)
def get_conversation(
    conversation_id: int,
    current_user=Depends(get_current_user)
):
    conversation = get_user_conversation(
        current_user['id'],
        conversation_id
    )

    if conversation is None:
        raise HTTPException(
            status_code=404,
            detail='Conversation not found.'
        )

    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    question,
                    answer,
                    sources_json,
                    created_at
                FROM conversation_messages
                WHERE conversation_id=%s
                AND user_id=%s
                ORDER BY id ASC
            """, (
                conversation_id,
                current_user['id']
            ))

            rows = cursor.fetchall()

    finally:
        connection.close()

    messages = []

    for row in rows:
        try:
            sources = json.loads(
                row['sources_json']
            )

            if not isinstance(
                sources,
                list
            ):
                sources = []

        except Exception:
            sources = []

        messages.append({
            'id': row['id'],
            'question': row['question'],
            'answer': row['answer'],
            'sources': [
                str(source)
                for source in sources
            ],
            'createdAt': row['created_at']
        })

    return {
        'success': True,
        'conversation': {
            'id': conversation['id'],
            'title': conversation['title'],
            'createdAt': conversation['created_at'],
            'updatedAt': conversation['updated_at']
        },
        'messages': messages
    }


@router.post(
    '/conversations/{conversation_id}/messages'
)
def save_conversation_message(
    conversation_id: int,
    request: ConversationMessageRequest,
    current_user=Depends(get_current_user)
):
    question = request.question.strip()
    answer = request.answer.strip()

    if not question:
        raise HTTPException(
            status_code=400,
            detail='Question cannot be empty.'
        )

    if not answer:
        raise HTTPException(
            status_code=400,
            detail='Answer cannot be empty.'
        )

    conversation = get_user_conversation(
        current_user['id'],
        conversation_id
    )

    if conversation is None:
        raise HTTPException(
            status_code=404,
            detail='Conversation not found.'
        )

    sources = [
        str(source)
        for source in request.sources
        if str(source).strip()
    ]

    now = datetime.now(
        timezone.utc
    ).isoformat()

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute("""
                INSERT INTO conversation_messages (
                    conversation_id,
                    user_id,
                    question,
                    answer,
                    sources_json,
                    created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (
                conversation_id,
                current_user['id'],
                question,
                answer,
                json.dumps(
                    sources,
                    ensure_ascii=False
                ),
                now
            ))

            cursor.execute("""
                SELECT COUNT(*)
                FROM conversation_messages
                WHERE conversation_id=%s
            """, (
                conversation_id,
            ))

            message_count = cursor.fetchone()['count']

            if message_count == 1:

                title = question

                if len(title) > 80:
                    title = (
                        title[:80].rstrip()
                        + '...'
                    )

                cursor.execute("""
                    UPDATE conversations
                    SET
                        title=%s,
                        updated_at=%s
                    WHERE id=%s
                    AND user_id=%s
                """, (
                    title,
                    now,
                    conversation_id,
                    current_user['id']
                ))

            else:

                cursor.execute("""
                    UPDATE conversations
                    SET updated_at=%s
                    WHERE id=%s
                    AND user_id=%s
                """, (
                    now,
                    conversation_id,
                    current_user['id']
                ))

        connection.commit()

    finally:
        connection.close()

    return {
        'success': True,
        'message': 'Conversation message saved.',
        'conversationId': conversation_id,
        'createdAt': now
    }


@router.delete(
    '/conversations/{conversation_id}'
)
def delete_conversation(
    conversation_id: int,
    current_user=Depends(get_current_user)
):
    conversation = get_user_conversation(
        current_user['id'],
        conversation_id
    )

    if conversation is None:
        raise HTTPException(
            status_code=404,
            detail='Conversation not found.'
        )

    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                DELETE FROM conversations
                WHERE id=%s
                AND user_id=%s
            """, (
                conversation_id,
                current_user['id']
            ))

        connection.commit()

    finally:
        connection.close()

    return {
        'success': True,
        'message': 'Conversation deleted.'
    }


# ============================================================
# ADMIN DASHBOARD
# ============================================================

@router.get('/admin/dashboard')
def admin_dashboard(
    current_admin=Depends(get_current_admin)
):
    stats = get_admin_dashboard_stats()

    return {
        'success': True,
        'admin': {
            'id': current_admin['id'],
            'fullName': current_admin['full_name'],
            'email': current_admin['email']
        },
        'stats': stats
    }


# ============================================================
# ADMIN USERS
# ============================================================

@router.get('/admin/users')
def admin_users(
    search: str = '',
    role: str = '',
    is_active: Optional[bool] = None,
    limit: int = 100,
    offset: int = 0,
    current_admin=Depends(get_current_admin)
):
    if limit < 1:
        limit = 1

    if limit > 500:
        limit = 500

    if offset < 0:
        offset = 0

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            conditions = []
            parameters = []

            if search.strip():
                search_value = (
                    f'%{search.strip()}%'
                )

                conditions.append("""
                    (
                        full_name ILIKE %s
                        OR email ILIKE %s
                    )
                """)

                parameters.extend([
                    search_value,
                    search_value
                ])

            if role.strip():

                normalized_role = (
                    role.strip().lower()
                )

                if normalized_role not in {
                    'user',
                    'admin'
                }:
                    raise HTTPException(
                        status_code=400,
                        detail='Role must be user or admin.'
                    )

                conditions.append(
                    'role=%s'
                )

                parameters.append(
                    normalized_role
                )

            if is_active is not None:
                conditions.append(
                    'is_active=%s'
                )

                parameters.append(
                    is_active
                )

            where_clause = ''

            if conditions:
                where_clause = (
                    'WHERE '
                    + ' AND '.join(conditions)
                )

            cursor.execute(
                f"""
                SELECT COUNT(*)
                FROM users
                {where_clause}
                """,
                parameters
            )

            total = cursor.fetchone()['count']

            cursor.execute(
                f"""
                SELECT
                    id,
                    full_name,
                    email,
                    role,
                    preferred_language,
                    is_active,
                    created_at,
                    last_login
                FROM users
                {where_clause}
                ORDER BY id DESC
                LIMIT %s
                OFFSET %s
                """,
                parameters + [
                    limit,
                    offset
                ]
            )

            rows = cursor.fetchall()

    finally:
        connection.close()

    users = []

    for row in rows:
        users.append({
            'id': row['id'],
            'fullName': row['full_name'],
            'email': row['email'],
            'role': row['role'],
            'preferredLanguage': row['preferred_language'],
            'isActive': bool(
                row['is_active']
            ),
            'createdAt': row['created_at'],
            'lastLogin': row['last_login']
        })

    return {
        'success': True,
        'total': total,
        'limit': limit,
        'offset': offset,
        'users': users
    }


# ============================================================
# ADMIN USER DETAILS
# ============================================================

@router.get(
    '/admin/users/{user_id}'
)
def admin_user_details(
    user_id: int,
    current_admin=Depends(get_current_admin)
):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    full_name,
                    email,
                    role,
                    preferred_language,
                    is_active,
                    created_at,
                    last_login
                FROM users
                WHERE id=%s
            """, (
                user_id,
            ))

            user = cursor.fetchone()

    finally:
        connection.close()

    if user is None:
        raise HTTPException(
            status_code=404,
            detail='User not found.'
        )

    counts = get_activity_summary(
        user_id
    )

    return {
        'success': True,
        'user': {
            'id': user['id'],
            'fullName': user['full_name'],
            'email': user['email'],
            'role': user['role'],
            'preferredLanguage': user['preferred_language'],
            'isActive': bool(
                user['is_active']
            ),
            'createdAt': user['created_at'],
            'lastLogin': user['last_login']
        },
        'activity': {
            'aiQuestions': counts['chat'],
            'standardsViewed': counts['standard_view'],
            'complianceChecks': counts['compliance_check'],
            'documents': (
                counts['document_upload']
                + counts['document_question']
            ),
            'documentUploads': counts['document_upload'],
            'documentQuestions': counts['document_question'],
            'servicesViewed': counts['service_view']
        }
    }


# ============================================================
# ADMIN USER ACTIVITY
# ============================================================

@router.get(
    '/admin/users/{user_id}/activity'
)
def admin_user_activity(
    user_id: int,
    current_admin=Depends(get_current_admin)
):
    connection = get_connection()

    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT
                    id,
                    full_name,
                    email
                FROM users
                WHERE id=%s
            """, (
                user_id,
            ))

            user = cursor.fetchone()

    finally:
        connection.close()

    if user is None:
        raise HTTPException(
            status_code=404,
            detail='User not found.'
        )

    counts = get_activity_summary(
        user_id
    )

    activities = get_user_activity_details(
        user_id
    )

    return {
        'success': True,
        'user': {
            'id': user['id'],
            'fullName': user['full_name'],
            'email': user['email']
        },
        'summary': {
            'aiQuestions': counts['chat'],
            'standardsViewed': counts['standard_view'],
            'complianceChecks': counts['compliance_check'],
            'documents': (
                counts['document_upload']
                + counts['document_question']
            ),
            'documentUploads': counts['document_upload'],
            'documentQuestions': counts['document_question'],
            'servicesViewed': counts['service_view']
        },
        'activities': activities
    }


# ============================================================
# ADMIN UPDATE USER
# ============================================================

@router.patch(
    '/admin/users/{user_id}'
)
def admin_update_user(
    user_id: int,
    request: AdminUserUpdateRequest,
    current_admin=Depends(get_current_admin)
):
    if (
        request.is_active is None
        and request.role is None
    ):
        raise HTTPException(
            status_code=400,
            detail='No user changes were provided.'
        )

    connection = get_connection()

    try:
        with connection.cursor() as cursor:

            cursor.execute("""
                SELECT
                    id,
                    full_name,
                    email,
                    role,
                    is_active
                FROM users
                WHERE id=%s
            """, (
                user_id,
            ))

            target_user = cursor.fetchone()

            if target_user is None:
                raise HTTPException(
                    status_code=404,
                    detail='User not found.'
                )

            if user_id == current_admin['id']:

                if (
                    request.is_active is False
                    or (
                        request.role is not None
                        and request.role.lower()
                        != 'admin'
                    )
                ):
                    raise HTTPException(
                        status_code=400,
                        detail=(
                            'You cannot deactivate or '
                            'remove your own administrator role.'
                        )
                    )

            new_role = target_user['role']

            if request.role is not None:

                new_role = (
                    request.role.strip().lower()
                )

                if new_role not in {
                    'user',
                    'admin'
                }:
                    raise HTTPException(
                        status_code=400,
                        detail='Role must be user or admin.'
                    )

            new_is_active = bool(
                target_user['is_active']
            )

            if request.is_active is not None:
                new_is_active = request.is_active

            removing_admin_access = (
                target_user['role'] == 'admin'
                and (
                    new_role != 'admin'
                    or not new_is_active
                )
            )

            if removing_admin_access:

                cursor.execute("""
                    SELECT COUNT(*)
                    FROM users
                    WHERE role='admin'
                    AND is_active=TRUE
                """)

                active_admin_count = (
                    cursor.fetchone()['count']
                )

                if active_admin_count <= 1:
                    raise HTTPException(
                        status_code=400,
                        detail=(
                            'At least one active administrator '
                            'must remain in the system.'
                        )
                    )

            cursor.execute("""
                UPDATE users
                SET
                    role=%s,
                    is_active=%s
                WHERE id=%s
            """, (
                new_role,
                new_is_active,
                user_id
            ))

            cursor.execute("""
                SELECT
                    id,
                    full_name,
                    email,
                    role,
                    preferred_language,
                    is_active,
                    created_at,
                    last_login
                FROM users
                WHERE id=%s
            """, (
                user_id,
            ))

            updated_user = cursor.fetchone()

        connection.commit()

    finally:
        connection.close()

    return {
        'success': True,
        'message': 'User updated successfully.',
        'user': {
            'id': updated_user['id'],
            'fullName': updated_user['full_name'],
            'email': updated_user['email'],
            'role': updated_user['role'],
            'preferredLanguage': updated_user['preferred_language'],
            'isActive': bool(
                updated_user['is_active']
            ),
            'createdAt': updated_user['created_at'],
            'lastLogin': updated_user['last_login']
        }
    }