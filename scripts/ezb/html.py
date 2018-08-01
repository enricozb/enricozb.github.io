structure = [
    "<!DOCTYPE html>",
    {"html": {
        "head": [
            '<meta name="viewport" content="width=device-width, initial-scale=1">',
            '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />',
            '<link rel="stylesheet" href="{css_file}">',
            """<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.10.0-beta/dist/katex.min.css" integrity="sha384-9tPv11A+glH/on/wEu99NVwDPwkMQESOocs/ZGXPoIiLE8MU/qkqUcZ3zzL+6DuH" crossorigin="anonymous">""",
            """<script src="https://cdn.jsdelivr.net/npm/katex@0.10.0-beta/dist/katex.min.js" integrity="sha384-U8Vrjwb8fuHMt6ewaCy8uqeUXv4oitYACKdB0VziCerzt011iQ/0TqlSlv8MReCm" crossorigin="anonymous"></script>""",
            """<script src="https://cdn.jsdelivr.net/npm/katex@0.10.0-beta/dist/contrib/auto-render.min.js" integrity="sha384-aGfk5kvhIq5x1x5YdvCp4upKZYnA8ckafviDpmWEKp4afOZEqOli7gqSnh8I6enH" crossorigin="anonymous"></script>""",
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
