import os
import sqlite3
import hashlib
import secrets
import json

from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel, EmailStr


# ============================================================
# PATHS
# ============================================================

BASE_DIR = Path(__file__).resolve().parent

DATABASE_PATH = BASE_DIR / "users.db"


# ============================================================
# JWT CONFIGURATION
# ============================================================

JWT_SECRET = os.getenv(
    "BIS_SAATHI_JWT_SECRET",
    "CHANGE_THIS_SECRET_BEFORE_PRODUCTION",
)

JWT_ALGORITHM = "HS256"

ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24


# ============================================================
# PASSWORD CONFIGURATION
# ============================================================

PASSWORD_ITERATIONS = 310_000


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/api/auth",
    tags=["Authentication"],
)


security = HTTPBearer(
    auto_error=False,
)


# ============================================================
# DATABASE
# ============================================================

def get_connection():
    connection = sqlite3.connect(
        DATABASE_PATH,
        check_same_thread=False,
    )

    connection.row_factory = sqlite3.Row

    connection.execute("PRAGMA foreign_keys = ON")

    return connection


def init_database():
    connection = get_connection()

    # --------------------------------------------------------
    # USERS TABLE
    # --------------------------------------------------------

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            full_name TEXT NOT NULL,

            email TEXT NOT NULL UNIQUE,

            password_hash TEXT NOT NULL,

            password_salt TEXT NOT NULL,

            role TEXT NOT NULL DEFAULT 'user',

            preferred_language TEXT NOT NULL DEFAULT 'English',

            is_active INTEGER NOT NULL DEFAULT 1,

            created_at TEXT NOT NULL,

            last_login TEXT
        )
        """
    )

    # --------------------------------------------------------
    # USER ACTIVITY TABLE
    # --------------------------------------------------------

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS user_activity (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            user_id INTEGER NOT NULL,

            activity_type TEXT NOT NULL,

            created_at TEXT NOT NULL,

            FOREIGN KEY (user_id)
                REFERENCES users(id)
                ON DELETE CASCADE
        )
        """
    )

    # --------------------------------------------------------
    # CONVERSATIONS TABLE
    # --------------------------------------------------------

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS conversations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            user_id INTEGER NOT NULL,

            title TEXT NOT NULL DEFAULT 'New Conversation',

            created_at TEXT NOT NULL,

            updated_at TEXT NOT NULL,

            FOREIGN KEY (user_id)
                REFERENCES users(id)
                ON DELETE CASCADE
        )
        """
    )

    # --------------------------------------------------------
    # CONVERSATION MESSAGES TABLE
    # --------------------------------------------------------

    connection.execute(
        """
        CREATE TABLE IF NOT EXISTS conversation_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,

            conversation_id INTEGER NOT NULL,

            user_id INTEGER NOT NULL,

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
        """
    )

    # --------------------------------------------------------
    # INDEXES
    # --------------------------------------------------------

    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_conversations_user
        ON conversations(user_id)
        """
    )

    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_messages_conversation
        ON conversation_messages(conversation_id)
        """
    )

    connection.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_messages_user
        ON conversation_messages(user_id)
        """
    )

    connection.commit()
    connection.close()


init_database()


# ============================================================
# PASSWORD HASHING
# ============================================================

def hash_password(
    password: str,
    salt: str | None = None,
):
    if salt is None:
        salt = secrets.token_hex(16)

    derived_key = hashlib.pbkdf2_hmac(
        "sha256",
        password.encode("utf-8"),
        salt.encode("utf-8"),
        PASSWORD_ITERATIONS,
    )

    password_hash = derived_key.hex()

    return password_hash, salt


def verify_password(
    password: str,
    stored_hash: str,
    stored_salt: str,
):
    calculated_hash, _ = hash_password(
        password,
        stored_salt,
    )

    return secrets.compare_digest(
        calculated_hash,
        stored_hash,
    )


# ============================================================
# JWT TOKEN
# ============================================================

def create_access_token(
    user_id: int,
    role: str,
):
    now = datetime.now(timezone.utc)

    expires = now + timedelta(
        minutes=ACCESS_TOKEN_EXPIRE_MINUTES,
    )

    payload = {
        "sub": str(user_id),
        "role": role,
        "iat": int(now.timestamp()),
        "exp": int(expires.timestamp()),
    }

    return jwt.encode(
        payload,
        JWT_SECRET,
        algorithm=JWT_ALGORITHM,
    )


# ============================================================
# CURRENT USER
# ============================================================

def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        security,
    ),
):
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Authentication required.",
        )

    token = credentials.credentials

    try:
        payload = jwt.decode(
            token,
            JWT_SECRET,
            algorithms=[JWT_ALGORITHM],
        )

        user_id = payload.get("sub")

        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token.",
            )

        user_id_int = int(user_id)

    except (
        JWTError,
        ValueError,
        TypeError,
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired authentication token.",
        )

    connection = get_connection()

    user = connection.execute(
        """
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
        WHERE id=?
        """,
        (user_id_int,),
    ).fetchone()

    connection.close()

    if user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User account not found.",
        )

    if not user["is_active"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="This user account is inactive.",
        )

    return dict(user)


# ============================================================
# ADMIN PROTECTION
# ============================================================

def get_current_admin(
    current_user=Depends(get_current_user),
):
    if current_user["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Administrator access required.",
        )

    return current_user


# ============================================================
# ACTIVITY TRACKING
# ============================================================

ALLOWED_ACTIVITY_TYPES = {
    "chat",
    "standard_view",
    "compliance_check",
    "document_upload",
    "document_question",
    "service_view",
}


def record_activity(
    user_id: int,
    activity_type: str,
):
    if activity_type not in ALLOWED_ACTIVITY_TYPES:
        return False

    connection = get_connection()

    connection.execute(
        """
        INSERT INTO user_activity (
            user_id,
            activity_type,
            created_at
        )
        VALUES (?, ?, ?)
        """,
        (
            user_id,
            activity_type,
            datetime.now(
                timezone.utc,
            ).isoformat(),
        ),
    )

    connection.commit()
    connection.close()

    return True


def get_activity_summary(
    user_id: int,
):
    connection = get_connection()

    rows = connection.execute(
        """
        SELECT
            activity_type,
            COUNT(*) AS total
        FROM user_activity
        WHERE user_id=?
        GROUP BY activity_type
        """,
        (user_id,),
    ).fetchall()

    connection.close()

    counts = {
        "chat": 0,
        "standard_view": 0,
        "compliance_check": 0,
        "document_upload": 0,
        "document_question": 0,
        "service_view": 0,
    }

    for row in rows:
        activity_type = row["activity_type"]

        if activity_type in counts:
            counts[activity_type] = row["total"]

    return counts


# ============================================================
# ADMIN HELPERS
# ============================================================

def get_admin_dashboard_stats():
    connection = get_connection()

    total_users = connection.execute(
        """
        SELECT COUNT(*)
        FROM users
        """
    ).fetchone()[0]

    active_users = connection.execute(
        """
        SELECT COUNT(*)
        FROM users
        WHERE is_active=1
        """
    ).fetchone()[0]

    inactive_users = connection.execute(
        """
        SELECT COUNT(*)
        FROM users
        WHERE is_active=0
        """
    ).fetchone()[0]

    admin_users = connection.execute(
        """
        SELECT COUNT(*)
        FROM users
        WHERE role='admin'
        """
    ).fetchone()[0]

    normal_users = connection.execute(
        """
        SELECT COUNT(*)
        FROM users
        WHERE role='user'
        """
    ).fetchone()[0]

    activity_rows = connection.execute(
        """
        SELECT
            activity_type,
            COUNT(*) AS total
        FROM user_activity
        GROUP BY activity_type
        """
    ).fetchall()

    connection.close()

    activity = {
        "chat": 0,
        "standard_view": 0,
        "compliance_check": 0,
        "document_upload": 0,
        "document_question": 0,
        "service_view": 0,
    }

    for row in activity_rows:
        activity_type = row["activity_type"]

        if activity_type in activity:
            activity[activity_type] = row["total"]

    return {
        "totalUsers": total_users,
        "activeUsers": active_users,
        "inactiveUsers": inactive_users,
        "adminUsers": admin_users,
        "normalUsers": normal_users,
        "aiQuestions": activity["chat"],
        "standardsViewed": activity["standard_view"],
        "complianceChecks": activity["compliance_check"],
        "documentUploads": activity["document_upload"],
        "documentQuestions": activity["document_question"],
        "documents": (
            activity["document_upload"]
            + activity["document_question"]
        ),
        "servicesViewed": activity["service_view"],
    }


def get_user_activity_details(
    user_id: int,
):
    connection = get_connection()

    rows = connection.execute(
        """
        SELECT
            id,
            activity_type,
            created_at
        FROM user_activity
        WHERE user_id=?
        ORDER BY id DESC
        LIMIT 100
        """,
        (user_id,),
    ).fetchall()

    connection.close()

    activities = []

    for row in rows:
        activities.append(
            {
                "id": row["id"],
                "activityType": row["activity_type"],
                "createdAt": row["created_at"],
            }
        )

    return activities


# ============================================================
# REQUEST MODELS
# ============================================================

class RegisterRequest(BaseModel):
    full_name: str
    email: EmailStr
    password: str
    preferred_language: str = "English"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class ActivityRequest(BaseModel):
    activity_type: str


class AdminUserUpdateRequest(BaseModel):
    is_active: Optional[bool] = None
    role: Optional[str] = None


class ConversationCreateRequest(BaseModel):
    title: str = "New Conversation"


class ConversationMessageRequest(BaseModel):
    question: str
    answer: str
    sources: list[str] = []


# ============================================================
# REGISTER
# ============================================================

@router.post("/register")
def register(
    request: RegisterRequest,
):
    full_name = request.full_name.strip()
    email = str(request.email).strip().lower()
    password = request.password

    if len(full_name) < 2:
        raise HTTPException(
            status_code=400,
            detail="Please enter your full name.",
        )

    if len(password) < 8:
        raise HTTPException(
            status_code=400,
            detail="Password must contain at least 8 characters.",
        )

    allowed_languages = {
        "English",
        "Hindi",
        "Marathi",
    }

    preferred_language = request.preferred_language

    if preferred_language not in allowed_languages:
        preferred_language = "English"

    connection = get_connection()

    existing_user = connection.execute(
        """
        SELECT id
        FROM users
        WHERE email=?
        """,
        (email,),
    ).fetchone()

    if existing_user is not None:
        connection.close()

        raise HTTPException(
            status_code=409,
            detail="An account with this email already exists.",
        )

    password_hash, password_salt = hash_password(
        password,
    )

    created_at = datetime.now(
        timezone.utc,
    ).isoformat()

    cursor = connection.execute(
        """
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
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            full_name,
            email,
            password_hash,
            password_salt,
            "user",
            preferred_language,
            1,
            created_at,
        ),
    )

    connection.commit()

    user_id = cursor.lastrowid

    connection.close()

    token = create_access_token(
        user_id,
        "user",
    )

    return {
        "success": True,
        "message": "Account created successfully.",
        "accessToken": token,
        "user": {
            "id": user_id,
            "fullName": full_name,
            "email": email,
            "role": "user",
            "preferredLanguage": preferred_language,
        },
    }


# ============================================================
# LOGIN
# ============================================================

@router.post("/login")
def login(
    request: LoginRequest,
):
    email = str(request.email).strip().lower()

    connection = get_connection()

    user = connection.execute(
        """
        SELECT *
        FROM users
        WHERE email=?
        """,
        (email,),
    ).fetchone()

    if user is None:
        connection.close()

        raise HTTPException(
            status_code=401,
            detail="Invalid email or password.",
        )

    if not user["is_active"]:
        connection.close()

        raise HTTPException(
            status_code=403,
            detail="This account is inactive.",
        )

    valid_password = verify_password(
        request.password,
        user["password_hash"],
        user["password_salt"],
    )

    if not valid_password:
        connection.close()

        raise HTTPException(
            status_code=401,
            detail="Invalid email or password.",
        )

    last_login = datetime.now(
        timezone.utc,
    ).isoformat()

    connection.execute(
        """
        UPDATE users
        SET last_login=?
        WHERE id=?
        """,
        (
            last_login,
            user["id"],
        ),
    )

    connection.commit()
    connection.close()

    token = create_access_token(
        user["id"],
        user["role"],
    )

    return {
        "success": True,
        "message": "Login successful.",
        "accessToken": token,
        "user": {
            "id": user["id"],
            "fullName": user["full_name"],
            "email": user["email"],
            "role": user["role"],
            "preferredLanguage": user["preferred_language"],
        },
    }


# ============================================================
# CURRENT USER
# ============================================================

@router.get("/me")
def me(
    current_user=Depends(get_current_user),
):
    return {
        "success": True,
        "user": {
            "id": current_user["id"],
            "fullName": current_user["full_name"],
            "email": current_user["email"],
            "role": current_user["role"],
            "preferredLanguage": current_user[
                "preferred_language"
            ],
            "isActive": bool(
                current_user["is_active"],
            ),
            "createdAt": current_user["created_at"],
            "lastLogin": current_user["last_login"],
        },
    }


# ============================================================
# GET CURRENT USER ACTIVITY
# ============================================================

@router.get("/activity")
def activity(
    current_user=Depends(get_current_user),
):
    counts = get_activity_summary(
        current_user["id"],
    )

    return {
        "success": True,
        "activity": {
            "aiQuestions": counts["chat"],
            "standardsViewed": counts["standard_view"],
            "complianceChecks": counts["compliance_check"],
            "documents": (
                counts["document_upload"]
                + counts["document_question"]
            ),
            "documentUploads": counts["document_upload"],
            "documentQuestions": counts["document_question"],
            "servicesViewed": counts["service_view"],
        },
    }


# ============================================================
# RECORD CURRENT USER ACTIVITY
# ============================================================

@router.post("/activity")
def create_activity(
    request: ActivityRequest,
    current_user=Depends(get_current_user),
):
    success = record_activity(
        current_user["id"],
        request.activity_type,
    )

    if not success:
        raise HTTPException(
            status_code=400,
            detail=(
                "Unsupported activity type. "
                "Use chat, standard_view, "
                "compliance_check, document_upload, "
                "document_question or service_view."
            ),
        )

    return {
        "success": True,
        "message": "Activity recorded.",
    }


# ============================================================
# CONVERSATION HELPERS
# ============================================================

def create_conversation_for_user(
    user_id: int,
    title: str = "New Conversation",
):
    now = datetime.now(
        timezone.utc,
    ).isoformat()

    clean_title = title.strip()

    if not clean_title:
        clean_title = "New Conversation"

    if len(clean_title) > 120:
        clean_title = clean_title[:120]

    connection = get_connection()

    cursor = connection.execute(
        """
        INSERT INTO conversations (
            user_id,
            title,
            created_at,
            updated_at
        )
        VALUES (?, ?, ?, ?)
        """,
        (
            user_id,
            clean_title,
            now,
            now,
        ),
    )

    conversation_id = cursor.lastrowid

    connection.commit()
    connection.close()

    return {
        "id": conversation_id,
        "title": clean_title,
        "createdAt": now,
        "updatedAt": now,
        "messageCount": 0,
    }


def get_user_conversation(
    user_id: int,
    conversation_id: int,
):
    connection = get_connection()

    conversation = connection.execute(
        """
        SELECT
            id,
            user_id,
            title,
            created_at,
            updated_at
        FROM conversations
        WHERE id=?
        AND user_id=?
        """,
        (
            conversation_id,
            user_id,
        ),
    ).fetchone()

    connection.close()

    return conversation


# ============================================================
# CONVERSATIONS - LIST
# ============================================================

@router.get("/conversations")
def list_conversations(
    current_user=Depends(get_current_user),
):
    connection = get_connection()

    rows = connection.execute(
        """
        SELECT
            c.id,
            c.title,
            c.created_at,
            c.updated_at,
            COUNT(m.id) AS message_count
        FROM conversations c
        LEFT JOIN conversation_messages m
            ON m.conversation_id=c.id
        WHERE c.user_id=?
        GROUP BY
            c.id,
            c.title,
            c.created_at,
            c.updated_at
        ORDER BY c.updated_at DESC
        """,
        (current_user["id"],),
    ).fetchall()

    connection.close()

    conversations = []

    for row in rows:
        conversations.append(
            {
                "id": row["id"],
                "title": row["title"],
                "createdAt": row["created_at"],
                "updatedAt": row["updated_at"],
                "messageCount": row["message_count"],
            }
        )

    return {
        "success": True,
        "conversations": conversations,
    }


# ============================================================
# CONVERSATIONS - CREATE
# ============================================================

@router.post("/conversations")
def create_conversation(
    request: ConversationCreateRequest,
    current_user=Depends(get_current_user),
):
    conversation = create_conversation_for_user(
        current_user["id"],
        request.title,
    )

    return {
        "success": True,
        "conversation": conversation,
    }


# ============================================================
# CONVERSATION - GET MESSAGES
# ============================================================

@router.get("/conversations/{conversation_id}")
def get_conversation(
    conversation_id: int,
    current_user=Depends(get_current_user),
):
    conversation = get_user_conversation(
        current_user["id"],
        conversation_id,
    )

    if conversation is None:
        raise HTTPException(
            status_code=404,
            detail="Conversation not found.",
        )

    connection = get_connection()

    rows = connection.execute(
        """
        SELECT
            id,
            question,
            answer,
            sources_json,
            created_at
        FROM conversation_messages
        WHERE conversation_id=?
        AND user_id=?
        ORDER BY id ASC
        """,
        (
            conversation_id,
            current_user["id"],
        ),
    ).fetchall()

    connection.close()

    messages = []

    for row in rows:
        try:
            sources = json.loads(
                row["sources_json"]
            )

            if not isinstance(sources, list):
                sources = []

        except Exception:
            sources = []

        messages.append(
            {
                "id": row["id"],
                "question": row["question"],
                "answer": row["answer"],
                "sources": [
                    str(source)
                    for source in sources
                ],
                "createdAt": row["created_at"],
            }
        )

    return {
        "success": True,
        "conversation": {
            "id": conversation["id"],
            "title": conversation["title"],
            "createdAt": conversation["created_at"],
            "updatedAt": conversation["updated_at"],
        },
        "messages": messages,
    }


# ============================================================
# CONVERSATION - SAVE MESSAGE
# ============================================================

@router.post("/conversations/{conversation_id}/messages")
def save_conversation_message(
    conversation_id: int,
    request: ConversationMessageRequest,
    current_user=Depends(get_current_user),
):
    question = request.question.strip()
    answer = request.answer.strip()

    if not question:
        raise HTTPException(
            status_code=400,
            detail="Question cannot be empty.",
        )

    if not answer:
        raise HTTPException(
            status_code=400,
            detail="Answer cannot be empty.",
        )

    conversation = get_user_conversation(
        current_user["id"],
        conversation_id,
    )

    if conversation is None:
        raise HTTPException(
            status_code=404,
            detail="Conversation not found.",
        )

    sources = [
        str(source)
        for source in request.sources
        if str(source).strip()
    ]

    now = datetime.now(
        timezone.utc,
    ).isoformat()

    connection = get_connection()

    connection.execute(
        """
        INSERT INTO conversation_messages (
            conversation_id,
            user_id,
            question,
            answer,
            sources_json,
            created_at
        )
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            conversation_id,
            current_user["id"],
            question,
            answer,
            json.dumps(
                sources,
                ensure_ascii=False,
            ),
            now,
        ),
    )

    # Automatically use the first question
    # as the conversation title.
    message_count = connection.execute(
        """
        SELECT COUNT(*)
        FROM conversation_messages
        WHERE conversation_id=?
        """,
        (conversation_id,),
    ).fetchone()[0]

    if message_count == 1:
        title = question

        if len(title) > 80:
            title = title[:80].rstrip() + "..."

        connection.execute(
            """
            UPDATE conversations
            SET
                title=?,
                updated_at=?
            WHERE id=?
            AND user_id=?
            """,
            (
                title,
                now,
                conversation_id,
                current_user["id"],
            ),
        )
    else:
        connection.execute(
            """
            UPDATE conversations
            SET updated_at=?
            WHERE id=?
            AND user_id=?
            """,
            (
                now,
                conversation_id,
                current_user["id"],
            ),
        )

    connection.commit()
    connection.close()

    return {
        "success": True,
        "message": "Conversation message saved.",
        "conversationId": conversation_id,
        "createdAt": now,
    }


# ============================================================
# CONVERSATION - DELETE
# ============================================================

@router.delete("/conversations/{conversation_id}")
def delete_conversation(
    conversation_id: int,
    current_user=Depends(get_current_user),
):
    conversation = get_user_conversation(
        current_user["id"],
        conversation_id,
    )

    if conversation is None:
        raise HTTPException(
            status_code=404,
            detail="Conversation not found.",
        )

    connection = get_connection()

    connection.execute(
        """
        DELETE FROM conversations
        WHERE id=?
        AND user_id=?
        """,
        (
            conversation_id,
            current_user["id"],
        ),
    )

    connection.commit()
    connection.close()

    return {
        "success": True,
        "message": "Conversation deleted.",
    }


# ============================================================
# ADMIN DASHBOARD
# ============================================================

@router.get("/admin/dashboard")
def admin_dashboard(
    current_admin=Depends(get_current_admin),
):
    stats = get_admin_dashboard_stats()

    return {
        "success": True,
        "admin": {
            "id": current_admin["id"],
            "fullName": current_admin["full_name"],
            "email": current_admin["email"],
        },
        "stats": stats,
    }


# ============================================================
# ADMIN - LIST USERS
# ============================================================

@router.get("/admin/users")
def admin_users(
    search: str = "",
    role: str = "",
    is_active: Optional[bool] = None,
    limit: int = 100,
    offset: int = 0,
    current_admin=Depends(get_current_admin),
):
    if limit < 1:
        limit = 1

    if limit > 500:
        limit = 500

    if offset < 0:
        offset = 0

    connection = get_connection()

    conditions = []
    parameters = []

    if search.strip():
        search_value = f"%{search.strip()}%"

        conditions.append(
            """
            (
                full_name LIKE ?
                OR email LIKE ?
            )
            """
        )

        parameters.extend(
            [
                search_value,
                search_value,
            ]
        )

    if role.strip():
        normalized_role = role.strip().lower()

        if normalized_role not in {
            "user",
            "admin",
        }:
            connection.close()

            raise HTTPException(
                status_code=400,
                detail="Role must be user or admin.",
            )

        conditions.append(
            "role=?"
        )

        parameters.append(
            normalized_role
        )

    if is_active is not None:
        conditions.append(
            "is_active=?"
        )

        parameters.append(
            1 if is_active else 0
        )

    where_clause = ""

    if conditions:
        where_clause = (
            "WHERE "
            + " AND ".join(conditions)
        )

    total = connection.execute(
        f"""
        SELECT COUNT(*)
        FROM users
        {where_clause}
        """,
        parameters,
    ).fetchone()[0]

    rows = connection.execute(
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
        LIMIT ?
        OFFSET ?
        """,
        parameters + [
            limit,
            offset,
        ],
    ).fetchall()

    users = []

    for row in rows:
        users.append(
            {
                "id": row["id"],
                "fullName": row["full_name"],
                "email": row["email"],
                "role": row["role"],
                "preferredLanguage": row[
                    "preferred_language"
                ],
                "isActive": bool(
                    row["is_active"]
                ),
                "createdAt": row["created_at"],
                "lastLogin": row["last_login"],
            }
        )

    connection.close()

    return {
        "success": True,
        "total": total,
        "limit": limit,
        "offset": offset,
        "users": users,
    }


# ============================================================
# ADMIN - USER DETAILS
# ============================================================

@router.get("/admin/users/{user_id}")
def admin_user_details(
    user_id: int,
    current_admin=Depends(get_current_admin),
):
    connection = get_connection()

    user = connection.execute(
        """
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
        WHERE id=?
        """,
        (user_id,),
    ).fetchone()

    connection.close()

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="User not found.",
        )

    counts = get_activity_summary(
        user_id
    )

    return {
        "success": True,
        "user": {
            "id": user["id"],
            "fullName": user["full_name"],
            "email": user["email"],
            "role": user["role"],
            "preferredLanguage": user[
                "preferred_language"
            ],
            "isActive": bool(
                user["is_active"]
            ),
            "createdAt": user["created_at"],
            "lastLogin": user["last_login"],
        },
        "activity": {
            "aiQuestions": counts["chat"],
            "standardsViewed": counts[
                "standard_view"
            ],
            "complianceChecks": counts[
                "compliance_check"
            ],
            "documents": (
                counts["document_upload"]
                + counts["document_question"]
            ),
            "documentUploads": counts[
                "document_upload"
            ],
            "documentQuestions": counts[
                "document_question"
            ],
            "servicesViewed": counts[
                "service_view"
            ],
        },
    }


# ============================================================
# ADMIN - USER ACTIVITY
# ============================================================

@router.get("/admin/users/{user_id}/activity")
def admin_user_activity(
    user_id: int,
    current_admin=Depends(get_current_admin),
):
    connection = get_connection()

    user = connection.execute(
        """
        SELECT
            id,
            full_name,
            email
        FROM users
        WHERE id=?
        """,
        (user_id,),
    ).fetchone()

    connection.close()

    if user is None:
        raise HTTPException(
            status_code=404,
            detail="User not found.",
        )

    counts = get_activity_summary(
        user_id
    )

    activities = get_user_activity_details(
        user_id
    )

    return {
        "success": True,
        "user": {
            "id": user["id"],
            "fullName": user["full_name"],
            "email": user["email"],
        },
        "summary": {
            "aiQuestions": counts["chat"],
            "standardsViewed": counts[
                "standard_view"
            ],
            "complianceChecks": counts[
                "compliance_check"
            ],
            "documents": (
                counts["document_upload"]
                + counts["document_question"]
            ),
            "documentUploads": counts[
                "document_upload"
            ],
            "documentQuestions": counts[
                "document_question"
            ],
            "servicesViewed": counts[
                "service_view"
            ],
        },
        "activities": activities,
    }


# ============================================================
# ADMIN - UPDATE USER
# ============================================================

@router.patch("/admin/users/{user_id}")
def admin_update_user(
    user_id: int,
    request: AdminUserUpdateRequest,
    current_admin=Depends(get_current_admin),
):
    if (
        request.is_active is None
        and request.role is None
    ):
        raise HTTPException(
            status_code=400,
            detail="No user changes were provided.",
        )

    connection = get_connection()

    target_user = connection.execute(
        """
        SELECT
            id,
            full_name,
            email,
            role,
            is_active
        FROM users
        WHERE id=?
        """,
        (user_id,),
    ).fetchone()

    if target_user is None:
        connection.close()

        raise HTTPException(
            status_code=404,
            detail="User not found.",
        )

    # --------------------------------------------------------
    # Protect current administrator
    # --------------------------------------------------------

    if user_id == current_admin["id"]:
        if (
            request.is_active is False
            or (
                request.role is not None
                and request.role.lower() != "admin"
            )
        ):
            connection.close()

            raise HTTPException(
                status_code=400,
                detail=(
                    "You cannot deactivate or "
                    "remove your own administrator role."
                ),
            )

    new_role = target_user["role"]

    if request.role is not None:
        new_role = request.role.strip().lower()

        if new_role not in {
            "user",
            "admin",
        }:
            connection.close()

            raise HTTPException(
                status_code=400,
                detail="Role must be user or admin.",
            )

    new_is_active = bool(
        target_user["is_active"]
    )

    if request.is_active is not None:
        new_is_active = request.is_active

    # --------------------------------------------------------
    # Protect last active administrator
    # --------------------------------------------------------

    removing_admin_access = (
        target_user["role"] == "admin"
        and (
            new_role != "admin"
            or not new_is_active
        )
    )

    if removing_admin_access:
        active_admin_count = connection.execute(
            """
            SELECT COUNT(*)
            FROM users
            WHERE role='admin'
            AND is_active=1
            """
        ).fetchone()[0]

        if active_admin_count <= 1:
            connection.close()

            raise HTTPException(
                status_code=400,
                detail=(
                    "At least one active administrator "
                    "must remain in the system."
                ),
            )

    connection.execute(
        """
        UPDATE users
        SET
            role=?,
            is_active=?
        WHERE id=?
        """,
        (
            new_role,
            1 if new_is_active else 0,
            user_id,
        ),
    )

    connection.commit()

    updated_user = connection.execute(
        """
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
        WHERE id=?
        """,
        (user_id,),
    ).fetchone()

    connection.close()

    return {
        "success": True,
        "message": "User updated successfully.",
        "user": {
            "id": updated_user["id"],
            "fullName": updated_user["full_name"],
            "email": updated_user["email"],
            "role": updated_user["role"],
            "preferredLanguage": updated_user[
                "preferred_language"
            ],
            "isActive": bool(
                updated_user["is_active"]
            ),
            "createdAt": updated_user["created_at"],
            "lastLogin": updated_user["last_login"],
        },
    }