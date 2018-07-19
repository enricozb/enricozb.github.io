import mistune


class EZBRenderer(mistune.Renderer):
    def paragraph(self, text):
        return f"<p>{text}</p>\n\n"

    def block_code(self, code, lang):
        if not lang:
            raise RuntimeError("codeblock without language specification")
        return f'<div class="code">\n{code}\n</div>\n'

    def codespan(self, code):
        return f"<ezb-code>{code}</ezb-code>"

def render(mdtxt):
    return mistune.Markdown(renderer=EZBRenderer())(mdtxt)

