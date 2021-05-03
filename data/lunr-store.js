---
# create lunr store for search page
#
---
{%- assign items = site.data[site.metadata] -%}
{%- assign posts = site.posts -%}
{% assign fields = site.data.config-search-blog | where_exp: 'f','f.nostore !="true"' -%}
{%- assign everything = posts | concat: items -%}
var store = [
    {%- for item in everything -%}
    {
        {% for f in fields %}{% if item[f.field] %}
        {{ f.field | jsonify }}: {{ item[f.field] | strip_html | truncatewords: 50 | normalize_whitespace | replace: '""','"' | jsonify }},{% endif %}
        {% endfor %}
        "title": {{ item['title'] | jsonify }},
        {% if item['date'] %}"date": {{ item['date'] | truncate: 10,"" | jsonify }},{%- endif -%}
        {% if item['tags'] %}"tags": {{ item['tags'] | join: ';' | jsonify }},{%- endif -%}
        {% if item['categories'] %}"categories": {{ item['categories'] | join: ';' | jsonify }},{%- endif -%}
        {% if item['subject'] %}"subject": {{ item['subject'] | jsonify }},{%- endif -%}
        "id": {% if item.objectid %}{{ '/collection/items/' | append: item.objectid | append: '.html' | jsonify }}{% else %}{{ item.url | jsonify }}{% endif %}
    }{%- unless forloop.last -%},{%- endunless -%}
    {%- endfor -%}
];
