# FROM python:3.9

# RUN apt-get update && apt-get install -y netcat-openbsd

# WORKDIR /app

# COPY requirements.txt .
# RUN pip install -r requirements.txt

# COPY . .

# CMD ["python", "app.py"]

FROM python:3.9

# Install MySQL server and netcat
RUN apt-get update && \
    apt-get install -y netcat-openbsd mysql-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure MySQL
RUN service mysql start && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword';" && \
    mysql -e "CREATE DATABASE student_portal;" && \
    service mysql stop

WORKDIR /app

# Install Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy application code
COPY . .

# Copy SQL files if they exist
COPY sql/ /docker-entrypoint-initdb.d/ 2>/dev/null || :

# Set environment variable
ENV DATABASE_URL=mysql+pymysql://root:rootpassword@localhost/student_portal

# Create database initialization script
RUN echo "CREATE TABLE IF NOT EXISTS students (\n\
    id INT AUTO_INCREMENT PRIMARY KEY,\n\
    name VARCHAR(100) NOT NULL,\n\
    email VARCHAR(100) UNIQUE NOT NULL,\n\
    password_hash VARCHAR(255) NOT NULL\n\
);\n\
\n\
CREATE TABLE IF NOT EXISTS courses (\n\
    id INT AUTO_INCREMENT PRIMARY KEY,\n\
    title VARCHAR(100) NOT NULL,\n\
    description TEXT\n\
);\n\
\n\
CREATE TABLE IF NOT EXISTS enrollments (\n\
    id INT AUTO_INCREMENT PRIMARY KEY,\n\
    student_id INT,\n\
    course_id INT,\n\
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,\n\
    FOREIGN KEY (student_id) REFERENCES students(id),\n\
    FOREIGN KEY (course_id) REFERENCES courses(id)\n\
);\n\
\n\
INSERT INTO courses (title, description) VALUES\n\
('Python Basics', 'تعلم أساسيات لغة بايثون'),\n\
('Web Development', 'دورة تطوير الويب باستخدام Flask و Django'),\n\
('Machine Learning Basics', 'Introduction to machine learning concepts and algorithms.'),\n\
('Cyber Security Fundamentals', 'Understanding key principles of cybersecurity and protecting digital assets.'),\n\
('Data Analysis with Python', 'Learn how to analyze and visualize data using Python and popular libraries.'),\n\
('Introduction to Cloud Computing', 'Explore cloud computing services and deployment models.'),\n\
('UI/UX Design Essentials', 'Fundamentals of user interface and user experience design principles.'),\n\
('Artificial Intelligence Applications', 'Explore real-world applications of AI, including NLP and computer vision.'),\n\
('Full-Stack Web Development', 'Learn front-end and back-end development using React, Node.js, and databases.'),\n\
('Mobile App Development', 'Introduction to building apps for iOS and Android using Flutter and Dart.'),\n\
('Big Data Analytics', 'Understand big data processing frameworks like Hadoop and Spark.'),\n\
('Ethical Hacking & Penetration Testing', 'Learn ethical hacking techniques to secure systems and networks.');" > /init.sql

# Create startup script
RUN echo '#!/bin/bash\n\
service mysql start\n\
while ! nc -z localhost 3306; do sleep 1; done\n\
mysql -u root -prootpassword student_portal < /init.sql\n\
for f in /docker-entrypoint-initdb.d/*.sql; do\n\
    [ -f "$f" ] && mysql -u root -prootpassword student_portal < "$f"\n\
done\n\
python app.py' > /start.sh && chmod +x /start.sh

EXPOSE 5000

CMD ["/start.sh"]