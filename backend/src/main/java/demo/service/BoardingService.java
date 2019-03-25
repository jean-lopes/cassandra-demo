package demo.service;

import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import demo.model.Boarding;
import demo.repository.BoardingRepository;
import reactor.core.publisher.Mono;

@Service
public class BoardingService {
    private static final Logger LOGGER = LoggerFactory.getLogger(BoardingService.class);
    
    @Autowired
    private BoardingRepository repository;

    
    
    public Mono<Boarding> save(Boarding boarding) {
        LOGGER.debug("saving {}", boarding);

        if (boarding.getId() == null) {
            boarding.setId(UUID.randomUUID());
        }

        return repository.save(boarding);
    }
    
    public Mono<Boarding> findById(UUID id) {
        LOGGER.debug("finding by id: {}", id);
        
        if (id == null) {
            return Mono.empty();
        }
        
        return repository.findById(id);
    }

}
