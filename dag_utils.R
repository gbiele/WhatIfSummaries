library(dagitty)
library(rethinking)
drawmydag = function(dag, cex = .75, lwd = 1, radius = 3.5) {
  
  label_clr = rep("black",length(names(dag)))
  names(label_clr) = names(dag)
  label_clr[which(names(dag) == latents(dag))] = "white"
  
  a_nodes = adjustedNodes(dag)
  l_nodes = latents(dag)
  
  shape_nodes = c(a_nodes,l_nodes)
  
  if (length(shape_nodes) > 0) {
    shps = vector(length = length(shape_nodes), mode = "list")
    names(shps) = shape_nodes
    clrshps = lapply(shps, function(x) "black")
    
    if (length(l_nodes) > 0) {
      clrshps[[l_nodes]] = adjustcolor("black",alpha = .25)
      shps[[l_nodes]] = "fc"
      clrshps = unlist(clrshps)
      clrshps = clrshps[l_nodes]
    } else {
      clrshps = unlist(clrshps)
    }
    
    if (length(a_nodes) > 0)
      shps[[adjustedNodes(dag)]] = "c"
  } else {
    clrshps = shps = NULL
  }
  
  drawdag(dag,
          latent_mark = "fc",
          col_shapes = clrshps,
          #col_labels = label_clr,
          cex = cex,
          shapes = shps,
          radius = radius,
          lwd = lwd)
}

get_xy = function(coord.list, nodes, axis, length.out = 200) {
  do.call(c,
          lapply(nodes, 
                 function(x) 
                   seq(coord.list[[axis]][x[1]],
                       coord.list[[axis]][x[2]],length.out = length.out))) 
}

plot_path = function(x,ys,k, arrow.col = "red") {
  lines(x[1:k],ys[1:k],col = arrow.col, lwd = 2)
  arrows(
    x0 = x[k-1],
    y0 = ys[k-1],
    x1 = x[k],
    y1 = ys[k],
    col = arrow.col,
    lwd = 2,
    length = .25/4
  )
}
flow_dag = function(dag, nodes, fn = NULL, arrow.col = "red", arrow.col2 = NULL, cex = 1,
                    fps = 25, length.out = 200, nodes2 = NULL, animation = TRUE, p.offset = 1.5) {
  
  arrow.col2 = ifelse(is.null(arrow.col2),arrow.col,arrow.col2)
  
  coord.list = coordinates(dag)
  x = get_xy(coord.list, nodes, "x", length.out = length.out)
  y = -1*get_xy(coord.list, nodes, "y", length.out = length.out)
  
  ys = smth.gaussian(y, tails = F)
  ys[which(is.na(ys))] = y[which(is.na(ys))]
  ys = ys + (.05*p.offset)*ifelse(diff(coord.list$y[nodes[[1]]])>0,-1,1)
  
  if(!is.null(nodes2)) {
    lo = length.out/(length(nodes2)/length(nodes))
    x2 = get_xy(coord.list, nodes2, "x", length.out = lo)
    y2 = -1*get_xy(coord.list, nodes2, "y", length.out = lo)
    
    ys2 = smth.gaussian(y2, tails = F)
    ys2[which(is.na(ys2))] = y2[which(is.na(ys2))]
    ys2 = ys2 + (.05*p.offset)*ifelse(diff(coord.list$y[nodes[[1]]])>0,-1,1)
  }
  if (animation == TRUE) {
    file.remove(list.files("anim",full.names = T))
    for (k in round(seq(2,length(x), length.out = 100))) {
      png(paste0("anim/anim",sprintf("%03d", k), ".png"),
          width = 3, height = 2.5, units = "in", res = 300)
      drawmydag(dag, cex = cex)
      plot_path(x,ys,k,arrow.col = arrow.col)
      if (!is.null(nodes2)) 
        plot_path(x2,ys2,k,arrow.col = arrow.col2)
      dev.off()
    }
    make_gif("anim",fn, fps = fps)
  } else {
    drawmydag(dag, cex = cex)
    plot_path(x,ys,length(x),arrow.col = arrow.col)
    if (!is.null(nodes2)) 
      plot_path(x2,ys2,length(x),arrow.col = arrow.col2)
  }
}

make_gif = function(dir = NULL, fn = NULL, fps = 20) {
  ## list file names and read in
  imgs <- list.files("anim", full.names = TRUE)
  img_list <- lapply(imgs, magick::image_read)
  
  ## join the images together
  img_joined <- image_join(img_list)
  
  ## animate at 20 frames per second
  img_animated <- image_animate(img_joined, fps = fps) 
  
  ## view animated image
  # img_animated
  
  ## save to disk
  image_write(image = img_animated,
              path = fn)
}
