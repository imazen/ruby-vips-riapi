class Rect
  attr_accessor :left
  attr_accessor :top
  attr_accessor :width
  attr_accessor :height

  def initialize(left, top, width, height)
    @left   = left
    @top    = top
    @width  = width
    @height = height
  end

  def right
    @left + @width
  end

  def bottom
    @top + @height
  end

  def xc
    @left + @width / 2
  end

  def yc
    @top + @height / 2
  end

  def empty?
    width == 0 or height == 0
  end

  def norm!(b)
    if width < 0
      left += width
      width *= -1
    end

    if height < 0
      top += height
      height *= -1
    end
  end

  def intersect(b)
    l = [ left,   b.left   ].max
    t = [ top,    b.top    ].max
    r = [ right,  b.right  ].min
    b = [ bottom, b.bottom ].min

    Rect.new l, t, r - l, b - t
  end

  def inspect
    "(Rect left #{left} top #{top} width #{width} height #{height})" 
  end
end
