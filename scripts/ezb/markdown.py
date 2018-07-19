import mistune

from pygments import highlight
from pygments.formatter import Formatter
from pygments.lexers import get_lexer_by_name
from pygments.token import *


class EZBFormatter(Formatter):
    ttype_to_tag = {
        Keyword: "ezb-op",
        Keyword.Import: "ezb-import",
        Comment: "ezb-cmt",
        Operator: "ezb-op",
        Name.Builtin: "ezb-builtin",
        Name.Function: "ezb-builtin",
        String: "ezb-str",
        Number: "ezb-num",
    }

    special_tokens = {
        "import": Keyword.Import,
        "from": Keyword.Import,
        "True": Number,
        "False": Number,
    }

    def format(self, tokensource, outfile):
        for ttype, token in tokensource:
            ttype = EZBFormatter.special_tokens.get(token, ttype)

            if ttype in EZBFormatter.ttype_to_tag:
                tag = EZBFormatter.ttype_to_tag[ttype]
                outfile.write(f"<{tag}>{token}</{tag}>")
            elif ttype.parent in EZBFormatter.ttype_to_tag:
                tag = EZBFormatter.ttype_to_tag[ttype.parent]
                outfile.write(f"<{tag}>{token}</{tag}>")
            else:
                outfile.write(f"{token}")


class EZBRenderer(mistune.Renderer):
    def paragraph(self, text):
        return f"<p>{text}</p>\n\n"

    def block_code(self, code, lang):
        if not lang:
            raise RuntimeError("codeblock without language specification")

        if lang == "python":
            lang = "python3"

        code = mistune.escape(code)
        code = highlight(code, get_lexer_by_name(lang), EZBFormatter())
        code = code.replace("\n", "<br>").replace(" ", "&nbsp;")
        return f'<div class="code">\n{code}\n</div>\n'

    def codespan(self, code):
        return f"<ezb-code>{code}</ezb-code>"


def render(mdtxt):
    return mistune.Markdown(renderer=EZBRenderer())(mdtxt)

