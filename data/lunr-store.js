---
# create lunr store for search page
---
{%- assign items = site.data[site.metadata] -%}
{%- assign posts = site.posts -%}

{%- assign fields = site.data.config-search -%}
{%- assign blogfields = site.data.config-search-blog -%}


var store = [ 
{%- for post in posts -%} 
{ "id": {{ post.url | jsonify }}, "title": {{ post.title | jsonify}}, "excerpt": {{ post.content | strip_html | truncatewords: 50 | jsonify}}, {% if post.tags.size > 0 %}"tags": "{% for tag in post.tags %}<a class='mx-2' href='/posts/#{{ tag }}'>{{ tag }}</a> {%endfor%}",{% endif%} {% if post.categories.size > 0 %}"categories": "{% for cat in post.categories %}<a href='/series/#{{ cat | downcase | remove: ' '}}.html'>{{ cat }}</a>{%endfor%}",{% endif%} {% for f in blogfields %}{% unless f.nostore %}{{ f.field | jsonify }}: {% if post[f.field] %}{{ post[f.field] | strip_html  |normalize_whitespace | replace: '""','"' | jsonify }}{% else %}"none"{% endif %}{% unless forloop.last %},{% endunless %}{% endunless %}{% endfor %}  },{%- endfor -%}
{%- for item in items -%} 
{ "id": {{ item.objectid | jsonify }}, {% for f in fields %}{{ f.field | jsonify }}: {% if item[f.field] %}{{ item[f.field] | normalize_whitespace | replace: '""','"' | jsonify }}{% else %}"none"{% endif %}{% unless forloop.last %},{% endunless %}{% endfor %} }{%- unless forloop.last -%},{%- endunless -%}
{%- endfor -%}
];
