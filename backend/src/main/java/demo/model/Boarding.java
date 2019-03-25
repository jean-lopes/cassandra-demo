package demo.model;

import java.time.Instant;
import java.time.LocalDateTime;
import java.util.UUID;

import javax.validation.constraints.Future;
import javax.validation.constraints.NotBlank;
import javax.validation.constraints.NotNull;
import javax.validation.constraints.Positive;

import org.springframework.data.cassandra.core.mapping.Column;
import org.springframework.data.cassandra.core.mapping.PrimaryKey;
import org.springframework.data.cassandra.core.mapping.Table;

import com.fasterxml.jackson.annotation.JsonFormat;
import com.fasterxml.jackson.annotation.JsonProperty;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Table("boardings")
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Boarding {
    @PrimaryKey
    private UUID id;
    
    @NotBlank(message = "Shipper is mandatory")
    private String shipper;
    
    @NotBlank(message = "Origin is mandatory")
    private String origin;
    
    @NotBlank(message = "Destiny is mandatory")
    private String destiny;
    
    @NotNull(message = "Mileage is mandatory")
    @Positive(message = "Mileage must be positive")
    private Long mileage;
    
    @NotNull(message = "Category is mandatory")
    private Category category;
    
    @NotNull(message = "Weight is mandatory")
    @Positive(message = "Weight must be positive")
    private Long weight;
    
    @NotNull(message = "Collection date is mandatory")
    @Future(message = "Collection date must be a future timestamp" )
    @Column("collection_date")
    @JsonProperty("collection_date")
    private LocalDateTime collectionDate;
}
