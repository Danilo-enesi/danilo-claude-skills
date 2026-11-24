<?php

namespace Front\Main\Components;

use Illuminate\View\Component;

class PictureWebP extends Component
{
    public $media;
    public $classes;
    public $default;
    public $thumbName;
    public $data_attr;
    /**
     * Create a new component instance.
     *
     * @return void
     */
    public function __construct($media, $classes = "", $default="placeholder-image", $thumbName = "thumb", $data_attr="")
    {
        $this->media = $media;
        $this->classes = $classes;
        $this->default = $default;
        $this->thumbName = $thumbName;
        $this->data_attr = $data_attr;
    }

    /**
     * Get the view / contents that represent the component.
     *
     * @return \Illuminate\Contracts\View\View|\Closure|string
     */
    public function render()
    {
        return view('components.picture-web-p');
    }
}
