-- ALTER DATABASE maquillajetiti CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;
-- ALTER TABLE materials CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- ALTER TABLE materials CHANGE m_name m_name VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- INSERT INTO materials (`m_name`) VALUES ("Base | 文字化け | 乱码 | 亂碼 | кракозя́бр");
-- INSERT INTO materials (`m_name`) VALUES ("Base | 💩 | 𝌆 | 🍻 | đčćž | لإعلان العالمى");
-- INSERT INTO materials (`m_name`) VALUES ("! ٩๏̯͡๏)۶ ლʕಠᴥಠʔლ");

UPDATE bulks set b_price=radians(rand());
