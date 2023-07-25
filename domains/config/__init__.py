from pydantic_settings import BaseSettings
from pydantic_settings import SettingsConfigDict

from domains.fs import dirs


class Config(BaseSettings):
    model_config = SettingsConfigDict(
        case_sensitive=True,
        env_file_encoding="utf-8",
        env_file=dirs.DIR_REPO / ".env",
        env_prefix="WEBAPP_",
        extra="ignore",
        frozen=True,
    )

    MODE_DEBUG: bool = False
    MSSQL_DATABASE_HOST: str
    MSSQL_DATABASE_NAME: str
    MSSQL_DATABASE_PASSWORD: str
    MSSQL_DATABASE_PORT: int
    MSSQL_DATABASE_USERNAME: str
    PRIMARY_DATABASE_URL: str
    SECRET_KEY: str
