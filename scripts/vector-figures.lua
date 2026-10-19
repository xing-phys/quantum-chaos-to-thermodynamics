-- Use the checked-in vector sibling for LaTeX; leave HTML PNGs unchanged.
function Image(image)
  if FORMAT:match('latex') and image.src:match('^figs/.*%.png$') then
    image.src = image.src:gsub('%.png$', '.pdf')
  end
  return image
end
