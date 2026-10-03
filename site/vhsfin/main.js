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

// Touch screens have no hover: a tap slides a tape out, another tap (or a tap
// anywhere else) slides it back.
if (matchMedia("(hover: none)").matches) {
  const spines = [...document.querySelectorAll(".spine")];
  for (const spine of spines) {
    spine.addEventListener("click", (event) => {
      event.stopPropagation();
      const out = !spine.classList.contains("out");
      spines.forEach((s) => s.classList.remove("out"));
      spine.classList.toggle("out", out);
    });
  }
  document.addEventListener("click", () => spines.forEach((s) => s.classList.remove("out")));
}
