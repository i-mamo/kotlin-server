package com.example.demo

import com.fasterxml.jackson.annotation.JsonProperty
import org.springframework.jdbc.core.JdbcTemplate
import org.springframework.web.bind.annotation.*
import java.util.*

data class BookRequest(
    val name: String,
    val person_name: String,
) {
    constructor() : this("", "")
}

data class JsonResponse(
    @JsonProperty("status") val status: Int,
    @JsonProperty("message") val message: String,
)

@RestController
//@RequestMapping("/books")
class BookController(private val jdbcTemplate: JdbcTemplate) {
    @GetMapping("/")
    fun getAllBooks(): String {
        return "Hello World!!!"
    }

    @PostMapping("/api/create")
    fun insert(@RequestBody bookRequest: BookRequest): JsonResponse {
        val name = bookRequest.name
        val person_name = bookRequest.person_name

        return try {

            // トランザクションの開始
            jdbcTemplate.execute("BEGIN")

            // 本のデータを挿入
            val rowsAffectedBooks =
                jdbcTemplate.update("INSERT INTO books (name,uid) VALUES ('$name','${UUID.randomUUID()}')")
            if (rowsAffectedBooks != 1) {
                throw Exception("Failed to insert book")
            }

            // 人物のデータを挿入
            val rowsAffectedPersons = jdbcTemplate.update("INSERT INTO persons (name) VALUES ('$person_name')")
            if (rowsAffectedPersons != 1) {
                throw Exception("Failed to insert person")
            }

            // 著者のデータを挿入
            val rowsAffectedAuthors =
                jdbcTemplate.update("INSERT INTO authors (book_id, person_id) SELECT b.id,p.id FROM books as b LEFT JOIN persons as p ON b.id = p.id WHERE b.name = '$name'")
            if (rowsAffectedAuthors != 1) {
                throw Exception("Failed to insert author")
            }

            // トランザクションのコミット
            jdbcTemplate.execute("COMMIT")

            JsonResponse(200, "success::bookを追加しました")

        } catch (e: Exception) {
            jdbcTemplate.execute("ROLLBACK")
            JsonResponse(500, "error::${e.message}")
        }

    }
}