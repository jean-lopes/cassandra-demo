package demo.controller;

import java.util.UUID;

import javax.validation.Valid;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import demo.model.Boarding;
import demo.service.BoardingService;
import reactor.core.publisher.Mono;

@RestController
@RequestMapping("boardings")
@CrossOrigin
public class BoardingController {
    
    @Autowired
    private BoardingService service;
    
    @PostMapping
    Mono<Boarding> newBoarding(@Valid @RequestBody Boarding boarding) {
        return service.save(boarding);
    }

    @GetMapping("/{id}")
    Mono<Boarding> findById(@PathVariable UUID id) {
        return service.findById(id);
    }
}
