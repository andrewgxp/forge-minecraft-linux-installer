# Dockerfile

# Base image with Java 21
FROM eclipse-temurin:25

# Add a user called Minecraft to run the commands for better security
# See https://www.docker.com/blog/understanding-the-docker-user-instruction/ for more details
RUN groupadd -g 1001 minecraft && \
    useradd -m -u 1001 -g minecraft minecraft

# Set working directory and ensure that the new minecraft user:group has permissions
WORKDIR /server
RUN chown -R minecraft:minecraft /server

# Sets the user to Minecraft to avoid the commands below from being run as root the security purposes outlined in the article above
USER minecraft

# Forge version build argument (e.g., 1.20.1-47.2.0)
ARG FORGE_VERSION
ENV FORGE_VERSION=${FORGE_VERSION}

# Download Forge installer
RUN curl -o forge-installer.jar https://maven.minecraftforge.net/net/minecraftforge/forge/${FORGE_VERSION}/forge-${FORGE_VERSION}-installer.jar

# Run the Forge installer to generate run.sh, libraries, etc.
RUN java -jar forge-installer.jar --installServer

# Accept EULA
RUN echo "eula=true" > eula.txt

# Add default server.properties (you can also COPY your own file here!)
ADD --chown=minecraft:minecraft https://raw.githubusercontent.com/vxgxp/forge-minecraft-linux-installer/main/server.properties server.properties

# Modify run.sh to include -nogui for headless mode
RUN sed -i 's#^java @user_jvm_args.txt @libraries/net/minecraftforge/forge/.*unix_args.txt.*#java @user_jvm_args.txt @libraries/net/minecraftforge/forge/'"$FORGE_VERSION"'/unix_args.txt -nogui "$@"#' run.sh

# Expose default Minecraft port
EXPOSE 25565

# Start the server
CMD ["bash", "run.sh"]
