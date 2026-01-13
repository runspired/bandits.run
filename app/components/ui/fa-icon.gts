import Component from '@glimmer/component';
import { icon, type IconDefinition } from '@fortawesome/fontawesome-svg-core';

interface FaIconSignature {
  Args: {
    icon: IconDefinition;
    class?: string;
    size?: string;
    fixedWidth?: boolean;
  };
}

export default class FaIcon extends Component<FaIconSignature> {
  get renderedIcon() {
    const iconObj = icon(this.args.icon, {
      classes: this.args.class ? [this.args.class] : [],
    });
    return iconObj.html[0];
  }

  <template>
    <span class="fa-icon-wrapper {{if @fixedWidth 'fa-fw'}}" ...attributes>
      {{! @glint-ignore - safe HTML from Font Awesome }}
      {{! template-lint-disable no-triple-curlies }}
      {{{this.renderedIcon}}}
    </span>
  </template>
}
