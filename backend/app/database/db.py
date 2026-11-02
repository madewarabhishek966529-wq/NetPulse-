import os
from datetime import datetime, timezone
from pathlib import Path
from sqlalchemy import (
    create_engine, Column, Integer, String, BigInteger, DateTime, Text
)
from sqlalchemy.orm import declarative_base, sessionmaker

# Determine database path
def get_database_url() -> str:
    if os.environ.get("TESTING") == "1":
        return "sqlite:///:memory:"

    if "NETPULSE_DATA_DIR" in os.environ:
        data_dir = Path(os.environ["NETPULSE_DATA_DIR"])
    else:
        data_dir = Path(".netpulse_data")

    data_dir.mkdir(parents=True, exist_ok=True)
    db_file = data_dir / "netpulse_backend.db"
    return f"sqlite:///{db_file.resolve().as_posix()}"


DATABASE_URL = get_database_url()


engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False, "timeout": 15},
    echo=False
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()


class DownloadRecord(Base):
    __tablename__ = "downloads"

    id = Column(Integer, primary_key=True, index=True)
    gid = Column(String(64), unique=True, index=True, nullable=False)
    url = Column(Text, nullable=False)
    filename = Column(String(512), nullable=False)
    file_size = Column(BigInteger, default=0)
    downloaded_size = Column(BigInteger, default=0)
    speed = Column(BigInteger, default=0)
    status = Column(String(32), default="waiting", index=True)
    destination = Column(Text, nullable=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))
    completed_at = Column(DateTime, nullable=True)


class DownloadHistoryRecord(Base):
    __tablename__ = "download_history"

    id = Column(Integer, primary_key=True, index=True)
    filename = Column(String(512), nullable=False)
    source_url = Column(Text, nullable=False)
    file_size = Column(BigInteger, default=0)
    status = Column(String(32), default="completed")
    completed_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class SettingRecord(Base):
    __tablename__ = "settings"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String(128), unique=True, index=True, nullable=False)
    value = Column(Text, nullable=False)


class BrowserEventRecord(Base):
    __tablename__ = "browser_events"

    id = Column(Integer, primary_key=True, index=True)
    source = Column(String(64), default="chrome")
    url = Column(Text, nullable=False)
    received_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    status = Column(String(32), default="received")


class AnalyzerHistoryRecord(Base):
    __tablename__ = "analyzer_history"

    id = Column(Integer, primary_key=True, index=True)
    original_url = Column(Text, nullable=False)
    discovered_count = Column(Integer, default=0)
    filtered_count = Column(Integer, default=0)
    analysis_status = Column(String(32), default="success")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


def init_db():
    Base.metadata.create_all(bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
