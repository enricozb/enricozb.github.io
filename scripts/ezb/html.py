structure = [
    "<!DOCTYPE html>",
    {"html": {
        "head": [
            '<meta name="viewport" content="width=device-width, initial-scale=1">',
            '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />',
            '<link rel="stylesheet" href="{css_file}">',
            """<link rel="stylesheet" href="{katex_css_file}">""",
            """<script src="{katex_js_file}"></script>""",
            """<script src="{autorender_js_file}"></script>""",
            '<title>{title}</title>'
            ],
        "body": [
            '<a id="home" href="{thoughts_file}">&larr;</a>',
            {'#maindivalt': [
                '<div id="title">{post_title}{post_subtitle}</div>',
                '{post_body}',
                {'#footer-links': {
                    'ul': [
                        '<li><a href="{prev_post}">{prev_name}</a></li>',
                        '<li><a href="{next_post}">Next</a></li>',
                    ]
                }},
            ]},
            '</div>',
            '</div>',
"""<script>
  renderMathInElement(
    document.body,
    {
      delimiters: [
        {left: "$$", right: "$$", display: true},
        {left: "$", right: "$", display: false},
      ]
    }
  );
</script>"""
        ]
    }}
]
