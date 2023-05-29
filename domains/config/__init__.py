from pydantic import BaseSettings

from domains.fs import dirs


class Config(BaseSettings):
    class Config:
        case_sensitive = True
        env_file = dirs.DIR_REPO / ".env"
        env_file_encoding = "utf-8"
        env_prefix = "WEBAPP_"
        frozen = True

    MODE_DEBUG: bool = False
    MSSQL_DATABASE_HOST: str
    MSSQL_DATABASE_NAME: str
    MSSQL_DATABASE_PASSWORD: str
    MSSQL_DATABASE_PORT: int
    MSSQL_DATABASE_USERNAME: str
    PRIMARY_DATABASE_URL: str
    SECRET_KEY: str
