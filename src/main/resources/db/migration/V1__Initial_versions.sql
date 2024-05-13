DROP TABLE IF EXISTS books;
CREATE TABLE IF NOT EXISTS books (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    stock Int Default 0 NOT NULL,
    uid VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DROP TABLE IF EXISTS authors;
CREATE TABLE IF NOT EXISTS authors (
    id SERIAL PRIMARY KEY,
    book_id  INT NOT NULL,
    person_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
DROP TABLE IF EXISTS persons;
CREATE TABLE IF NOT EXISTS persons (
    id SERIAL PRIMARY KEY,
    name  VARCHAR(255) NOT NULL,
    note VARCHAR(255) DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE OR REPLACE FUNCTION trigger_set_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

--CREATE TRIGGER set_timestamp
--BEFORE UPDATE ON books
--FOR EACH ROW
--EXECUTE PROCEDURE trigger_set_timestamp()

DROP TRIGGER IF EXISTS set_timestamp ON books;
DROP TRIGGER IF EXISTS set_timestamp ON authors;
DROP TRIGGER IF EXISTS set_timestamp ON persons;

DO $$
DECLARE
  -- postgresの管理用テーブルやflyway関連以外で、UPDATED_ATカラムを持つテーブルを抽出（その他除外したいテーブルはここに書く）
  has_updated_at_tables CURSOR FOR
    SELECT t.table_name FROM information_schema.tables t
      INNER JOIN information_schema.columns c ON c.table_name = t.table_name
        AND c.table_schema = t.table_schema
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE'
      AND t.table_name != 'flyway_schema_history'
      AND c.column_name ILIKE 'UPDATED_AT'; -- ファイル上の定義は大文字だが、POSTGRES上は小文字扱いなため、ILIKEで検索している
  table_name VARCHAR;
BEGIN
  OPEN has_updated_at_tables;
  LOOP
    -- テーブル名を取得、取得できなくなればループ終了
    FETCH has_updated_at_tables INTO table_name;
      EXIT WHEN NOT FOUND;
    EXECUTE format(
      'CREATE TRIGGER set_timestamp
  BEFORE UPDATE ON %s
  FOR EACH ROW
  EXECUTE PROCEDURE trigger_set_timestamp()',
      table_name
    );
  END LOOP;
END
$$ LANGUAGE PLPGSQL;