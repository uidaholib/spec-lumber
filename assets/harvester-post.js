---
# this file provides the most recent post to display on the Spec home page
---
/* most recent Harvester post */
{% assign post = site.posts | first %}
var harvesterPost = {
    link: "{{ post.url | prepend: site.baseurl | prepend: site.url }}",
    title: {{ post.title | jsonify }},
    image: "{% include image/post-image.html %}",
    image_small: "{% include image/post-small.html %}",
    image_thumb: "{% include image/post-thumb.html %}",
    excerpt: {{ post.excerpt | strip_html | truncatewords: 50 | jsonify }},
    date: "{{ post.date | date: '%Y-%m-%d' }}"
};
