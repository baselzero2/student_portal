document.addEventListener("DOMContentLoaded", function () {
    // --- تبديل الوضع المظلم ---
    const themeToggle = document.getElementById("theme-toggle");

    if (themeToggle) {
        const currentTheme = getCookie("theme") || "light";
        document.body.classList.toggle("dark-mode", currentTheme === "dark");

        themeToggle.addEventListener("click", function () {
            const newTheme = document.body.classList.contains("dark-mode") ? "light" : "dark";
            document.body.classList.toggle("dark-mode");
            setCookie("theme", newTheme, 365);
        });
    }

    // --- تسجيل الدورة عبر AJAX ---
    const buttons = document.querySelectorAll(".enroll-btn");

    buttons.forEach(button => {
        button.addEventListener("click", function () {
            button.disabled = true;
            button.textContent = "جارٍ التسجيل...";

            const courseId = this.getAttribute("data-course-id");

            fetch("/ajax/enroll", {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({ course_id: courseId })
            })
            .then(response => response.json())
            .then(data => {
                alert(data.message);
            })
            .catch(error => {
                console.error("Error:", error);
                alert("حدث خطأ أثناء التسجيل. حاول مرة أخرى.");
            })
            .finally(() => {
                button.disabled = false;
                button.textContent = "تسجيل في الدورة";
            });
        });
    });

    // --- وظائف ملفات تعريف الارتباط ---
    function setCookie(name, value, days) {
        let expires = "";
        if (days) {
            let date = new Date();
            date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
            expires = "; expires=" + date.toUTCString();
        }
        document.cookie = name + "=" + value + "; path=/" + expires;
    }

    function getCookie(name) {
        let nameEQ = name + "=";
        let ca = document.cookie.split(";");
        for (let i = 0; i < ca.length; i++) {
            let c = ca[i].trim();
            if (c.indexOf(nameEQ) == 0) return c.substring(nameEQ.length, c.length);
        }
        return null;
    }
});
