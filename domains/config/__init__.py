from pydantic import BaseSettings

from domains.fs import dirs


class Config(BaseSettings):
    class Config:
        case_sensitive = True
        env_file = dirs.DIR_REPO / ".env"
        env_file_encoding = "utf-8"
        env_prefix = "XXX_"
        frozen = True

    DATABASE_HOST: str
    DATABASE_NAME: str
    DATABASE_PASSWORD: str
    DATABASE_PORT: int
    DATABASE_USERNAME: str
    MODE_DEBUG: bool = False
    SECRET_KEY: str
