package com.meusaas.api;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.nio.file.Files;
import java.nio.file.Paths;

@SpringBootApplication
public class ApiApplication {

    public static void main(String[] args) {
        // Verifica se o .env está um nível acima (na raiz do projeto) ou na pasta atual
        String envPath = Files.exists(Paths.get("../.env")) ? "../" : "./";
        Dotenv dotenv = Dotenv.configure()
                .directory(envPath)
                .ignoreIfMissing()
                .load();

        // Injeta as variáveis de ambiente no sistema para o Spring Boot ler
        dotenv.entries().
                forEach(entry -> {
                    System.setProperty(entry.getKey(), entry.getValue());
                });

        SpringApplication.run(ApiApplication.class, args);
    }
}