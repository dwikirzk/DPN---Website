document.addEventListener("DOMContentLoaded", () => {
  const loginBtn = document.querySelector(".login-btn");
  const loginModal = document.getElementById("loginModal");
  const closeModal = document.getElementById("closeModal");
  const loginForm = document.getElementById("loginForm");

  // Open modal
  if (loginBtn && loginModal) {
    loginBtn.addEventListener("click", (e) => {
      e.preventDefault();
      loginModal.classList.add("active");
      document.body.style.overflow = "hidden"; // Disable background scroll
    });
  }

  // Close modal function
  const closeLoginModal = () => {
    loginModal.classList.remove("active");
    document.body.style.overflow = ""; // Re-enable background scroll
  };

  // Close modal via close button
  if (closeModal) {
    closeModal.addEventListener("click", closeLoginModal);
  }

  // Close modal via clicking overlay background
  if (loginModal) {
    loginModal.addEventListener("click", (e) => {
      if (e.target === loginModal) {
        closeLoginModal();
      }
    });
  }

  // Close modal via Escape key
  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && loginModal.classList.contains("active")) {
      closeLoginModal();
    }
  });

  // Handle form submission
  if (loginForm) {
    loginForm.addEventListener("submit", (e) => {
      e.preventDefault();
      const email = document.getElementById("loginEmail").value;
      alert(`Selamat datang kembali! Login berhasil sebagai ${email}`);
      closeLoginModal();
    });
  }

  // Countdown timer logic (dynamic countdown)
  const countdownTimer = document.querySelector(".countdown-timer");
  if (countdownTimer) {
    // Set target date to 1 day, 14 hours, 14 minutes, 37 seconds from now
    const targetDate = new Date();
    targetDate.setDate(targetDate.getDate() + 1);
    targetDate.setHours(targetDate.getHours() + 14);
    targetDate.setMinutes(targetDate.getMinutes() + 14);
    targetDate.setSeconds(targetDate.getSeconds() + 37);

    const updateTimer = () => {
      const now = new Date().getTime();
      const difference = targetDate - now;

      if (difference <= 0) {
        clearInterval(timerInterval);
        return;
      }

      const days = Math.floor(difference / (1000 * 60 * 60 * 24));
      const hours = Math.floor(
        (difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60),
      );
      const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
      const seconds = Math.floor((difference % (1000 * 60)) / 1000);

      const timeBoxes = countdownTimer.querySelectorAll(".time-box .number");
      if (timeBoxes.length === 4) {
        timeBoxes[0].textContent = String(days).padStart(2, "0");
        timeBoxes[1].textContent = String(hours).padStart(2, "0");
        timeBoxes[2].textContent = String(minutes).padStart(2, "0");
        timeBoxes[3].textContent = String(seconds).padStart(2, "0");
      }
    };

    updateTimer();
    const timerInterval = setInterval(updateTimer, 1000);
  }
});
