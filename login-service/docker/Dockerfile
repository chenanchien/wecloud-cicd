FROM maven:3.8.4-jdk-8-slim

WORKDIR /app

# Copy the code into the container
COPY . .

# Compile the application
RUN mvn clean package -DskipTests

# Run the JAR file
ENTRYPOINT ["java", "-jar", "target/login-0.1.0.jar"]
