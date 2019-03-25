package demo.repository;

import java.util.UUID;

import org.springframework.data.cassandra.repository.ReactiveCassandraRepository;

import demo.model.Boarding;

public interface BoardingRepository extends ReactiveCassandraRepository<Boarding, UUID> {
    
}
