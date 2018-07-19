structure = {
    "html": {
        "head": [
            '<meta name="viewport" content="width=device-width, initial-scale=1">',
            '<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />',
            '<link rel="stylesheet" href="{css_file}">',
            '<title>{title}</title>'
            ],
        "body": [
            '<a id="home" href="{thoughts_file}">←</a>',
            {'#maindivalt': [
                '<div id="title">{post_title}</div>',
                '{post_body}',
                {'#footer-links': {
                    'ul': [
                        '<li><a href="{prev_post}">Previous</a></li>',
                        '<li><a href="{next_post}">Next</a></li>',
                    ]
                }},
            ]},
            '</div>',
            '</div>'
        ]
    }
}

