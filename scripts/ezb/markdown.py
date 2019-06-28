import mistune
import re
import string

from colorama import init, Fore, Style
init()

from nltk.tokenize import TweetTokenizer
from pygments import highlight
from pygments.formatter import Formatter
from pygments.lexers import get_lexer_by_name
from pygments.token import *

class MathBlockGrammar(mistune.BlockGrammar):
    block_math = re.compile("^\$\$(.*?)\$\$", re.DOTALL)
    latex_environment = re.compile(
        r"^\\begin\{([a-z]*\*?)\}(.*?)\\end\{\1\}",
        re.DOTALL
    )


class MathBlockLexer(mistune.BlockLexer):
    default_rules = ['block_math', 'latex_environment'] + \
        mistune.BlockLexer.default_rules

    def __init__(self, rules=None, **kwargs):
        if rules is None:
            rules = MathBlockGrammar()
        super(MathBlockLexer, self).__init__(rules, **kwargs)

    def parse_block_math(self, m):
        """Parse a $$math$$ block"""
        self.tokens.append({
            'type': 'block_math',
            'text': m.group(1)
        })

    def parse_latex_environment(self, m):
        self.tokens.append({
            'type': 'latex_environment',
            'name': m.group(1),
            'text': m.group(2)
        })


class MathInlineGrammar(mistune.InlineGrammar):
    math = re.compile("^\$(.+?)\$")
    text = re.compile(r'^[\s\S]+?(?=[\\<!\[_*`~$]|https?://| {2,}\n|$)')


class MathInlineLexer(mistune.InlineLexer):
    default_rules = ['math'] + mistune.InlineLexer.default_rules

    def __init__(self, renderer, rules=None, **kwargs):
        if rules is None:
            rules = MathInlineGrammar()
        super(MathInlineLexer, self).__init__(renderer, rules, **kwargs)

    def output_math(self, m):
        return self.renderer.inline_math(m.group(1))


class EZBMarkdown(mistune.Markdown):
    def __init__(self, renderer, **kwargs):
        if 'inline' not in kwargs:
            kwargs['inline'] = MathInlineLexer
        if 'block' not in kwargs:
            kwargs['block'] = MathBlockLexer
        super(EZBMarkdown, self).__init__(renderer, **kwargs)

    def output_block_math(self):
        return self.renderer.block_math(self.token['text'])

    def output_latex_environment(self):
        return self.renderer.latex_environment(
            self.token['name'], self.token['text']
        )


class EZBRenderer(mistune.Renderer):
    def block_math(self, text):
        return f"$${text}$$"

    def latex_environment(self, name, text):
        return fr"$$\begin{{{name}}}{text}\end{{{name}}}$$"

    def inline_math(self, text):
        return f"${text}$"

    def paragraph(self, text):
        return f"<p>{text}</p>\n\n"

    def block_code(self, code, lang):
        if not lang:
            raise RuntimeError("codeblock without language specification")

        if lang == "python":
            lang = "python3"

        code = highlight(code, get_lexer_by_name(lang), EZBFormatter())
        code = code.replace("\n", "<br>\n").replace(" ", "&nbsp;")
        return f'<div class="code">\n{code}\n</div>\n'

    def codespan(self, code):
        return f"<ezb-code>{code}</ezb-code>"


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
        tokensource = list(tokensource)
        backtick_env = None
        backtick_skip = False
        for i, (ttype, token) in enumerate(tokensource):
            if backtick_skip:
                if token == "]":
                    backtick_skip = False
                continue

            ttype = EZBFormatter.special_tokens.get(token, ttype)

            if token == "`":
                if backtick_env:
                    backtick_env = None
                else:
                    try:
                        j = 1
                        new_token = ""
                        while tokensource[i + j][1] != "]":
                            new_token += tokensource[i + j][1]
                            j += 1

                        backtick_env = eval(new_token)
                        backtick_skip = True
                    except:
                        print(f"  {Fore.YELLOW}skipped backtick{Style.RESET_ALL}")
                        outfile.write("`")
                        continue
                continue

            if backtick_env:
                ttype = backtick_env

            if ttype == Name and tokensource[i + 1][1] == "(":
                ttype = Name.Function

            if ttype in EZBFormatter.ttype_to_tag:
                tag = EZBFormatter.ttype_to_tag[ttype]
                outfile.write(f"<{tag}>{token}</{tag}>")
            elif ttype.parent in EZBFormatter.ttype_to_tag:
                tag = EZBFormatter.ttype_to_tag[ttype.parent]
                outfile.write(f"<{tag}>{token}</{tag}>")
            else:
                outfile.write(f"{token}")


def render(mdtxt):
    markdown = EZBMarkdown(renderer=EZBRenderer())
    return markdown(mdtxt)

