CREATE DATABASE default_db;
CREATE USER 'gemini'@'%' IDENTIFIED BY 'change_me';
GRANT ALL PRIVILEGES ON default_db.* TO 'gemini'@'%';
FLUSH PRIVILEGES;