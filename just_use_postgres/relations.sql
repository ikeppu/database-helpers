-- 1:1 Table
-- Таблица пользователей
CREATE TABLE
    users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) NOT NULL
    );

-- Таблица профилей (связь 1:1 с users)
CREATE TABLE
    profiles (
        id SERIAL PRIMARY KEY,
        bio TEXT,
        user_id INTEGER UNIQUE NOT NULL, -- UNIQUE делает связь 1:1
        CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES users (id)
    );

-- One to many 1:M
-- Таблица авторов
CREATE TABLE
    authors (id SERIAL PRIMARY KEY, name VARCHAR(100) NOT NULL);

-- Таблица книг (у одного автора много книг)
CREATE TABLE
    books (
        id SERIAL PRIMARY KEY,
        title VARCHAR(200) NOT NULL,
        author_id INTEGER NOT NULL, -- Здесь НЕТ UNIQUE, так как у автора много книг
        CONSTRAINT fk_author FOREIGN KEY (author_id) REFERENCES authors (id)
    );

-- Many to Many M:M
-- Таблица студентов
CREATE TABLE
    students (id SERIAL PRIMARY KEY, name VARCHAR(100));

-- Таблица курсов
CREATE TABLE
    courses (id SERIAL PRIMARY KEY, title VARCHAR(100));

-- Промежуточная таблица (связующее звено)
CREATE TABLE
    enrollments (
        id SERIAL PRIMARY KEY, -- Твой обязательный ID для каждой таблицы
        student_id INTEGER REFERENCES students (id) ON DELETE CASCADE,
        course_id INTEGER REFERENCES courses (id) ON DELETE CASCADE,
        UNIQUE (student_id, course_id) -- Чтобы нельзя было записать одного и того же студента на один курс дважды
    );