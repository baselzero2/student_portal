CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS enrollments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT,
    course_id INT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_id) REFERENCES courses(id)
);

INSERT INTO courses (title, description) VALUES
('Python Basics', 'تعلم أساسيات لغة بايثون'),
('Web Development', 'دورة تطوير الويب باستخدام Flask و Django'),
('Machine Learning Basics', 'Introduction to machine learning concepts and algorithms.'),
('Cyber Security Fundamentals', 'Understanding key principles of cybersecurity and protecting digital assets.'),
('Data Analysis with Python', 'Learn how to analyze and visualize data using Python and popular libraries.'),
('Introduction to Cloud Computing', 'Explore cloud computing services and deployment models.'),
('UI/UX Design Essentials', 'Fundamentals of user interface and user experience design principles.'),
('Artificial Intelligence Applications', 'Explore real-world applications of AI, including NLP and computer vision.'),
('Full-Stack Web Development', 'Learn front-end and back-end development using React, Node.js, and databases.'),
('Mobile App Development', 'Introduction to building apps for iOS and Android using Flutter and Dart.'),
('Big Data Analytics', 'Understand big data processing frameworks like Hadoop and Spark.'),
('Ethical Hacking & Penetration Testing', 'Learn ethical hacking techniques to secure systems and networks.');