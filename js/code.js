/// Modify the content of `div.code` blocks so
/// they are indented correctly when rendered.
function main() {
  const whitespace = /^ */;
  const blocks = document.querySelectorAll("div.code");
  for (const block of blocks) {
    const text = block.innerHTML;
    const lines = text.split("\n").slice(1);
    const leading = lines?.[0].match(whitespace)?.[0].length || 0;

    const formatted = lines.map((line) => line.substring(leading)).join("<br>");

    block.innerHTML = `<pre>${formatted}</pre>`;
  }
}

main();
