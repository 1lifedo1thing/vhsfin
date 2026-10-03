// Lights up, tape goes in, then the movie keeps playing. Without this script
// (or with reduced motion) the poster frame simply stays put.
const intro = document.querySelector(".tv .intro");
const loop = document.querySelector(".tv .loop");
const still = matchMedia("(prefers-reduced-motion: reduce)").matches;

if (intro && loop && !still) {
  intro.addEventListener("ended", () => {
    loop.currentTime = 0;
    loop.play().then(() => loop.classList.add("on")).catch(() => {});
  });
  // Let the room fade up before the tape moves.
  setTimeout(() => intro.play().catch(() => {}), 1100);
}
