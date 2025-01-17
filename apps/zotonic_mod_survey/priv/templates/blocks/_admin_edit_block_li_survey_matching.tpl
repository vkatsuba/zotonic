{% extends "admin_edit_widget_i18n.tpl" %}

{% block widget_title %}
{_ Block _}
<div class="widget-header-tools"></div>
{% endblock %}

{% block widget_show_minimized %}false{% endblock %}
{% block widget_id %}edit-block-{{ name }}{% endblock %}
{% block widget_header %}{% endblock %}

{% block widget_content %}
    {% if id.is_editable %}
      <div class="form-group">
         <input class="form-control" type="text" id="block-{{name}}-prompt{{ lang_code_for_id }}" name="blocks[].prompt{{ lang_code_with_dollar }}" value="{{ blk.prompt[lang_code]  }}"
                 placeholder="{_ Matching question _} ({{ lang_code }})" />
      </div>

      <div class="form-group view-expanded">
          <textarea class="form-control" id="block-{{name}}-explanation{{ lang_code_for_id }}" name="blocks[].explanation{{ lang_code_with_dollar }}" rows="2"
                 placeholder="{_ Explanation _} ({{ lang_code }})" >{{ blk.explanation[lang_code]  }}</textarea>
      </div>

      <div class="form-group view-expanded">
         <textarea class="form-control" id="block-{{name}}-matching{{ lang_code_for_id }}" name="blocks[].matching{{ lang_code_with_dollar }}" rows="4"
                placeholder="{_ Apple = Red _} ({{ lang_code }})" >{{ blk.matching[lang_code]  }}</textarea>

          {#
          <p class="help-block">
            <strong>{_ Example: _}</strong><br>
            {_ Apple = Red<br>Milk = White<br>Vienna = Austria<br> Flying dutchman = Wagner._}
          </p>
          #}
      </div>

      {% include "_admin_block_test_feedback.tpl" %}

    {% else %}
        <p>{{ blk.narrative[lang_code]  }}</p>
    {% endif %}
{% endblock %}

{% block widget_content_nolang %}
    <div class="row">
        <div class="col-md-6">
            <div class="form-group view-expanded">
                <div class="checkbox">
                  <label>
                      <input type="checkbox" id="block-{{name}}-is_random" name="blocks[].is_random" value="1" {% if blk.is_random %}checked="checked"{% endif %} />
                      {_ Randomize answers _}
                  </label>
                </div>

                <div class="question-options">
                    <div class="checkbox">
                      <label>
                          <input type="checkbox" id="block-{{name}}-is_required" name="blocks[].is_required" value="1" {% if blk.is_required or is_new %}checked="checked"{% endif %} />
                          {_ Required, this question must be answered. _}
                      </label>
                    </div>
                    <div class="checkbox">
                      <label>
                          <input type="checkbox" id="block-{{name}}-is_hide_result" name="blocks[].is_hide_result" value="1" {% if blk.is_hide_result %}checked="checked"{% endif %} />
                          {_ Hide from results _}
                      </label>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-md-6">
            {#
              {% include "_admin_block_test_checkbox.tpl" %}
            #}
        </div>
    </div>
{% endblock %}
