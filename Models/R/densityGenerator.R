


library(kernlab)
#library(plot3D)


##############
# Generate a random density distribution
#    following a scaling law with params alpha>0, Pmax (P_i = Pmax*i^{-\alpha})
#  
#  Value :
#     Spatial matrix of distribution values
#
#  Parameters :
#     - gridSize : width of the square grid
#     - N : number of kernels (cities)
#     - alpha : rank-size scaling parameter
#
#
#   NOT USED YET
#     - proba = TRUE : return a probability distribution
#     - rmin = 0 : minimal radius of cities (uniformaly drawn within rmlin,rmax) ; gridSize/N if 0
#     - rmax = 0 : idem
#     - Pmax = 1 : population of the greatest city (useful if proba == FALSE)
#     - tolThreshold : DEPRECATED
#     - kernel_type = "poisson" : can be "gaussian" (sigma=1/(2*r^2)) or "poisson" (sigma=1/r)
spatializedExpMixtureDensity <- function(gridSize,N,alpha,centerDensity,proba=TRUE,rmin=0,rmax=0,Pmax=1,tolThreshold=0,kernel_type="poisson"){
  
  #if(rmin==0){rmin = gridSize/N}
  #if(rmax==0){rmax = gridSize/N}
  
  # patches of the grid are 1 unit size (in r_min/max units)
  grid = matrix(0,gridSize,gridSize)
  
  # matrix of coordinates
  coords = matrix(c(c(matrix(rep(1:gridSize,gridSize),nrow=gridSize)),c(matrix(rep(1:gridSize,gridSize),nrow=gridSize,byrow=TRUE))),nrow=gridSize^2)
  
  # first draw param distribs ? not needed
  # for exp distribs, P_i = 2pi*d_i*r_i^2
  #  -> take P from deterministic distrib ; draw r.
  
  for(i in 1:N){
    show(i)
    pop_i = Pmax*i^{-alpha}
    d_i = centerDensity
    r_i = sqrt(pop_i/(2*pi*d_i))
    show(r_i)
    #r_i = runif(1,min=rmin,max=rmax)
    #d_i = pop_i / (2*pi*(r_i^2))
    
    # find origin of that kernel
    #  -> one of points such that : d(bord) > rcut and \forall \vec{x}\in D(rcut),d(\vec{x})<tolThr.
    #pot = which(!pseudoClosing(grid>tolThreshold,r_i),arr.ind=TRUE)
    #show(length(pot))
    #if(length(pot)==0){
    #  # Take a point with minimal density ?
    #  pot = which(grid==min(grid),arr.ind=TRUE)
    #}
    
    # simplify : take deterministiquely (almost, after two exps only two points possible)
    # BUT not close to border
    #rbord = 2*rmax*log(Pmax/tolThreshold)
    #rbord = 2*rmax
    
    # random center
    # if(max(grid)==0){
    #   # random if no center yet
    #   center = matrix(runif(2,min=rbord+1,max=gridSize-rbord),nrow=1)
    # }
    # else {
    #   # else find min pop area not too close to border
    #   pot = which(grid==min(grid[(rbord+1):(gridSize-rbord),(rbord+1):(gridSize-rbord)]),arr.ind=TRUE)
    #   row = sample(nrow(pot),1)
    #   center = matrix(pot[row,],nrow=1)
    # }
    
    center = matrix(runif(2,min=1,max=gridSize),nrow=1)
    
    # add kernel : use kernlab laplace kernel or other
    #if(kernel_type=="poisson"){ker=laplacedot(sigma=1/r_i)}
    #if(kernel_type=="gaussian"){ker=rbfdot(sigma=1/(2*r_i^2))}
    #if(kernel_type="quadratic"){ker=} # is quad kernel available ?
    
    grid = grid + (d_i * matrix(kernelMatrix(kernel=laplacedot(sigma=1/r_i),x=coords,y=center),nrow=gridSize))
    
  }
  
  if(proba==TRUE){grid = grid / sum(grid)}
  
  return(grid)
}




# test the function
#test = spatializedExpMixtureDensity(50,10,0.7,0.005)
#persp3D(z=test)







##
# Dirty morpho mat closing
#   used to determine empirical scaling exponent
pseudoClosing <- function(mat,rcut){
  res=matrix(mat,nrow=nrow(mat))
  for(i in 1:nrow(mat)){
    for(j in 1:ncol(mat)){
      if(i>rcut&&i<nrow(mat)-rcut+1&&j>rcut&&j<ncol(mat)-rcut+1){
        # dirty that way - should be quicker with convol.
        # furthermore Manhattan distance, not best solution for distribs symmetric by rotation.
        if(sum(mat[(i-rcut):(i+rcut),(j-rcut):(j+rcut)])>=1){res[i,j]=TRUE}
      }else{res[i,j]=TRUE}
    }
  }
  return(res)
}




# test the scaling
#
# for counter proportionnal to density.

# cut at threshold, get sizes of each cluster.

# use connexAreas function of morphoAnalysis

# function giving slope as a function of theta
linFit <- function(d,theta){
  c = connexAreas(d>theta)
  pops = c()
  for(i in 1:length(c)){pops=append(pops,sum(d[c[[i]]]))}
  x=log(1:length(pops))
  y=log(sort(pops,decreasing=TRUE))
  return(lm(y~x,data.frame(x,y)))
}


# Empirical scaling exponent log(A_i) = K - alpha log(P_i)
empScalExp <- function(theta,lambda,beta,d){
  c = connexAreas(d>theta)
  pops = c();amens = c()
  for(i in 1:length(c)){
    pops=append(pops,sum(d[c[[i]]]))
    amens=append(amens,sum(lambda*d[c[[i]]]^beta))
  }
  x=log(pops)
  y=log(amens)
  fit = lm(y~x,data.frame(x,y))
  return(fit$coefficients[2])
}


#
#slope(test,0.02)
#persp3D(z=d)

#d=spatializedExpMixtureDensity(200,15,5,5,200,0.7,0.001)

#thetas=seq(from=0.01,to=0.2,by=0.005)
# be careful in thresholds, not good connex areas otherwise
# thetas given in proportion
#slopes=c();rsquared=c()
#for(theta in thetas){
#  l=linFit(d,theta*max(d))
#  slopes=append(slopes,l$coefficients[2])
#  rsquared=append(rsquared,summary(l)$adj.r.squared)
#}

#plot(thetas,-slopes)
#plot(thetas,rsquared)

# slope of slopes ?
#lm(-slopes~thetas,data.frame(thetas,slopes))$coefficients[2]


###############
## Morpho funs
###############



library(rlist)
# iterative version
propagate <- function(m,indices,ii,jj,n){
  pile = list(c(ii,jj))
  while(length(pile)>0){
    # unstack first
    coords = list.take(pile,1)[[1]] ; pile = list.remove(pile,1);
    i=coords[1];j=coords[2];
    # update indices
    indices[i,j]=n
    #stack neighbors of conditions are met
    if(i>1){if(indices[i-1,j]==0&&m[i-1,j]==TRUE){pile = list.prepend(pile,c(i-1,j))}}
    if(i<nrow(m)){if(indices[i+1,j]==0&&m[i+1,j]==TRUE){pile = list.prepend(pile,c(i+1,j))}}
    if(j>1){if(indices[i,j-1]==0&&m[i,j-1]==TRUE){pile = list.prepend(pile,c(i,j-1))}}
    if(j<ncol(m)){if(indices[i,j+1]==0&&m[i,j+1]==TRUE){pile = list.prepend(pile,c(i,j+1))}}
  }  
  return(indices)
}

connexAreas <- function(m){
  indices <- matrix(data=rep(0,nrow(m)*ncol(m)),nrow=nrow(m),ncol=ncol(m))
  maxArea = 0
  
  for(i in 1:nrow(m)){
    for(j in 1:ncol(m)){
      # if colored but not marked, mark recursively
      #   -- necessarily a new area
      if(m[i,j]==TRUE&&indices[i,j]==0){
        maxArea = maxArea + 1
        show(paste("Prop",i,j," - area ",maxArea))
        indices <- propagate(m,indices,i,j,maxArea)
      }
    }
  }
  
  
  # use indices to create list of coordinates
  
  areas = list()
  for(a in 1:maxArea){
    areas=list.append(areas,which(indices==a))
  }
  
  return(areas)
}






