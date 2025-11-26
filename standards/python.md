# Estándares Python

## Versiones soportadas

- Python 3.11+ (preferido 3.12)
- Type hints obligatorios
- Async cuando aplique (FastAPI, aiohttp)

## Estructura de proyecto

```
src/
├── app/
│   ├── __init__.py
│   ├── main.py                 # Entry point
│   ├── config.py               # Configuración con Pydantic
│   │
│   ├── domain/                 # Entidades y lógica de negocio
│   │   ├── __init__.py
│   │   ├── entities/
│   │   ├── value_objects/
│   │   ├── exceptions.py
│   │   └── interfaces.py
│   │
│   ├── application/            # Casos de uso
│   │   ├── __init__.py
│   │   ├── commands/
│   │   ├── queries/
│   │   └── dtos.py
│   │
│   ├── infrastructure/         # Implementaciones técnicas
│   │   ├── __init__.py
│   │   ├── database/
│   │   ├── repositories/
│   │   └── external_services/
│   │
│   └── presentation/           # API layer
│       ├── __init__.py
│       ├── api/
│       │   ├── v1/
│       │   │   ├── __init__.py
│       │   │   ├── routes.py
│       │   │   └── schemas.py
│       │   └── deps.py         # Dependencies
│       └── middleware/
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── unit/
│   └── integration/
│
├── pyproject.toml
└── README.md
```

## pyproject.toml base

```toml
[project]
name = "my-project"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "fastapi>=0.110.0",
    "uvicorn[standard]>=0.27.0",
    "pydantic>=2.6.0",
    "pydantic-settings>=2.2.0",
    "sqlalchemy>=2.0.0",
    "alembic>=1.13.0",
    "httpx>=0.27.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0.0",
    "pytest-asyncio>=0.23.0",
    "pytest-cov>=4.1.0",
    "ruff>=0.3.0",
    "mypy>=1.8.0",
    "pre-commit>=3.6.0",
]

[tool.ruff]
target-version = "py311"
line-length = 100

[tool.ruff.lint]
select = [
    "E",      # pycodestyle errors
    "W",      # pycodestyle warnings
    "F",      # pyflakes
    "I",      # isort
    "B",      # flake8-bugbear
    "C4",     # flake8-comprehensions
    "UP",     # pyupgrade
    "ARG",    # flake8-unused-arguments
    "SIM",    # flake8-simplify
]
ignore = ["E501"]  # line too long (handled by formatter)

[tool.ruff.lint.isort]
known-first-party = ["app"]

[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true
disallow_untyped_defs = true

[tool.pytest.ini_options]
asyncio_mode = "auto"
testpaths = ["tests"]
```

## Convenciones de código

### Type hints obligatorios

```python
from typing import TypeVar, Generic
from collections.abc import Sequence

# ✅ Tipos explícitos
def create_user(email: str, name: str) -> User:
    ...

# ✅ Opcionales explícitos
def find_user(user_id: str) -> User | None:
    ...

# ✅ Colecciones con tipos específicos
def get_users(status: UserStatus) -> list[User]:
    ...

def get_user_emails(users: Sequence[User]) -> set[str]:
    return {user.email for user in users}

# ✅ Generics
T = TypeVar("T")

class Repository(Generic[T]):
    async def get_by_id(self, id: str) -> T | None:
        ...
```

### Pydantic para schemas y configuración

```python
from pydantic import BaseModel, Field, EmailStr, field_validator
from pydantic_settings import BaseSettings

# ✅ Schemas inmutables por defecto
class UserCreate(BaseModel):
    email: EmailStr
    name: str = Field(min_length=2, max_length=100)
    
    model_config = {"frozen": True}

class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    created_at: datetime
    
    model_config = {"from_attributes": True}

# ✅ Validación custom
class OrderCreate(BaseModel):
    items: list[OrderItemCreate] = Field(min_length=1)
    
    @field_validator("items")
    @classmethod
    def validate_items(cls, v: list[OrderItemCreate]) -> list[OrderItemCreate]:
        if len(v) > 100:
            raise ValueError("Maximum 100 items per order")
        return v

# ✅ Settings con validación
class Settings(BaseSettings):
    database_url: str
    redis_url: str
    jwt_secret: str = Field(min_length=32)
    jwt_expiration_minutes: int = 60
    debug: bool = False
    
    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
    }
```

### Result pattern

```python
from dataclasses import dataclass
from typing import TypeVar, Generic

T = TypeVar("T")
E = TypeVar("E")

@dataclass(frozen=True, slots=True)
class Ok(Generic[T]):
    value: T
    
    @property
    def is_ok(self) -> bool:
        return True

@dataclass(frozen=True, slots=True)
class Err(Generic[E]):
    error: E
    
    @property
    def is_ok(self) -> bool:
        return False

Result = Ok[T] | Err[E]

# ✅ Uso en servicios
@dataclass(frozen=True)
class UserError:
    code: str
    message: str

async def create_user(
    email: str, 
    name: str,
    repo: UserRepository,
) -> Result[User, UserError]:
    existing = await repo.find_by_email(email)
    if existing:
        return Err(UserError(code="EMAIL_EXISTS", message="Email already registered"))
    
    user = User(id=generate_id(), email=email, name=name)
    await repo.save(user)
    return Ok(user)

# ✅ Consumer con pattern matching
match await create_user(email, name, repo):
    case Ok(user):
        return UserResponse.model_validate(user)
    case Err(error):
        raise HTTPException(status_code=400, detail=error.message)
```

### Domain entities

```python
from dataclasses import dataclass, field
from datetime import datetime
from uuid import uuid4

@dataclass
class Entity:
    id: str = field(default_factory=lambda: str(uuid4()))
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime | None = None

@dataclass
class User(Entity):
    email: str = ""
    name: str = ""
    status: UserStatus = UserStatus.ACTIVE
    
    def activate(self) -> None:
        if self.status == UserStatus.ACTIVE:
            raise InvalidStateError("User is already active")
        self.status = UserStatus.ACTIVE
        self.updated_at = datetime.utcnow()
    
    def deactivate(self) -> None:
        self.status = UserStatus.INACTIVE
        self.updated_at = datetime.utcnow()
```

### FastAPI patterns

```python
from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.responses import JSONResponse

app = FastAPI(
    title="User Service",
    version="1.0.0",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# ✅ Dependencies
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session() as session:
        yield session

async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: AsyncSession = Depends(get_db),
) -> User:
    user = await verify_token(token, db)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication credentials",
        )
    return user

# ✅ Routes
@app.get(
    "/api/v1/users/{user_id}",
    response_model=UserResponse,
    responses={
        404: {"description": "User not found"},
    },
)
async def get_user(
    user_id: str,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    user = await user_repo.get_by_id(db, user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"User {user_id} not found",
        )
    return UserResponse.model_validate(user)

@app.post(
    "/api/v1/users",
    response_model=UserResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_user(
    data: UserCreate,
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    result = await user_service.create(db, data.email, data.name)
    match result:
        case Ok(user):
            return UserResponse.model_validate(user)
        case Err(error):
            raise HTTPException(status_code=400, detail=error.message)
```

### Exception handling

```python
# ✅ Custom exceptions
class AppException(Exception):
    def __init__(
        self,
        message: str,
        code: str,
        status_code: int = 500,
    ) -> None:
        self.message = message
        self.code = code
        self.status_code = status_code
        super().__init__(message)

class NotFoundError(AppException):
    def __init__(self, resource: str, id: str) -> None:
        super().__init__(
            message=f"{resource} with id {id} not found",
            code="NOT_FOUND",
            status_code=404,
        )

class ValidationError(AppException):
    def __init__(self, message: str, details: list[dict]) -> None:
        self.details = details
        super().__init__(message=message, code="VALIDATION_ERROR", status_code=400)

# ✅ Global exception handler
@app.exception_handler(AppException)
async def app_exception_handler(request: Request, exc: AppException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": {
                "code": exc.code,
                "message": exc.message,
            }
        },
    )
```

### SQLAlchemy async

```python
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column

class Base(DeclarativeBase):
    pass

class UserModel(Base):
    __tablename__ = "users"
    
    id: Mapped[str] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(unique=True, index=True)
    name: Mapped[str]
    status: Mapped[str] = mapped_column(default="active")
    created_at: Mapped[datetime] = mapped_column(default=datetime.utcnow)

# ✅ Repository pattern
class UserRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session
    
    async def get_by_id(self, user_id: str) -> User | None:
        result = await self._session.execute(
            select(UserModel).where(UserModel.id == user_id)
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None
    
    async def save(self, user: User) -> None:
        model = UserModel(
            id=user.id,
            email=user.email,
            name=user.name,
            status=user.status.value,
        )
        self._session.add(model)
        await self._session.commit()
    
    @staticmethod
    def _to_entity(model: UserModel) -> User:
        return User(
            id=model.id,
            email=model.email,
            name=model.name,
            status=UserStatus(model.status),
            created_at=model.created_at,
        )
```

## Testing

```python
import pytest
from unittest.mock import AsyncMock, MagicMock

@pytest.fixture
def user_repo_mock() -> AsyncMock:
    return AsyncMock(spec=UserRepository)

@pytest.fixture
def user_service(user_repo_mock: AsyncMock) -> UserService:
    return UserService(user_repo_mock)

class TestUserService:
    async def test_create_user_success(
        self,
        user_service: UserService,
        user_repo_mock: AsyncMock,
    ) -> None:
        # Arrange
        user_repo_mock.find_by_email.return_value = None
        
        # Act
        result = await user_service.create("test@example.com", "John")
        
        # Assert
        assert result.is_ok
        assert result.value.email == "test@example.com"
        user_repo_mock.save.assert_called_once()
    
    async def test_create_user_email_exists(
        self,
        user_service: UserService,
        user_repo_mock: AsyncMock,
    ) -> None:
        # Arrange
        user_repo_mock.find_by_email.return_value = User(email="test@example.com", name="Existing")
        
        # Act
        result = await user_service.create("test@example.com", "John")
        
        # Assert
        assert not result.is_ok
        assert result.error.code == "EMAIL_EXISTS"

# ✅ Parametrized tests
@pytest.mark.parametrize(
    "email,expected_valid",
    [
        ("valid@example.com", True),
        ("invalid", False),
        ("", False),
        ("a" * 256 + "@test.com", False),
    ],
)
def test_email_validation(email: str, expected_valid: bool) -> None:
    result = validate_email(email)
    assert result.is_ok == expected_valid
```

## Checklist para el agente

Al escribir código Python:

- [ ] Type hints en todas las funciones
- [ ] Pydantic para validación y schemas
- [ ] Result pattern para operaciones fallibles
- [ ] Dataclasses para entities
- [ ] Async/await con SQLAlchemy 2.0
- [ ] Ruff para linting y formatting
- [ ] Mypy strict mode sin errores
- [ ] Tests con pytest-asyncio
- [ ] Pattern matching para Results
