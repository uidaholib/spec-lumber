---
layout: home
title: Home
pagination: 
  enabled: true
---
{% assign posts = paginator.posts | default: site.posts %}


<div class="posts-list">
  {% for post in posts offset: 1 %}
  <article class="post-preview">
    <a href="{{ post.url | absolute_url }}">
      <h2 class="post-title">{{ post.title }}</h2>
      {% if post.subtitle %}
        <h3 class="post-subtitle">
        {{ post.subtitle }}
        </h3>
      {% endif %}
    </a>

    <p class="post-meta">
      {% assign date_format = site.date_format | default: "%B %-d, %Y" %}
      Posted on {{ post.date | date: date_format }}
    </p>

    <div class="post-entry-container">
      {%if post.cover-image%}
      <div class="post-image">
        <a href="{{ post.url | absolute_url }}">
          <img src="{% include image/post-thumb.html%}">
        </a>
      </div>
      {% endif %}
      
      <div class="post-entry">
        {% assign excerpt_length = site.excerpt_length | default: 50 %}
        {{ post.excerpt | strip_html | xml_escape | truncatewords: excerpt_length }}
        {% assign excerpt_word_count = post.excerpt | number_of_words %}
        {% if post.content != post.excerpt or excerpt_word_count > excerpt_length %}
          <a href="{{ post.url | absolute_url }}" class="post-read-more">[Read&nbsp;More]</a>
        {% endif %}
      </div>
    </div>

    {% if post.tags.size > 0 %}
    <div class="blog-tags">
      Tags:
      {% if site.link-tags %}
      {% for tag in post.tags %}
      <a href="{{ '/tags' | absolute_url }}#{{- tag -}}">{{- tag -}}</a>
      {% endfor %}
      {% else %}
        {{ post.tags | join: ", " }}
      {% endif %}
    </div>
    {% endif %}

   </article>
  {% endfor %}
</div>

{% if paginator.total_pages > 1 %}
<ul class="pagination main-pager">
  {% if paginator.previous_page %}
  <li class="page-item previous">
    <a class="page-link" href="{{ paginator.previous_page_path | absolute_url }}">&larr; Newer Posts</a>
  </li>
  {% endif %}
  {% if paginator.next_page %}
  <li class="page-item next">
    <a class="page-link" href="{{ paginator.next_page_path | absolute_url }}">Older Posts &rarr;</a>
  </li>
  {% endif %}
</ul>
{% endif %}