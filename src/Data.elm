module Data exposing (tikz)

tikz : List (String, String)
tikz = [
  ("graph.tikz", graph)
  ,("complete-graph.tikz", completeGraph)
  ,("spheres.tikz", spheres)
  , ("lindemayer.tikz", lindemayer)
  ]

graph = """
\\begin{tikzpicture}[scale=1.0]
  % Axes
  \\draw[->] (-0.2,0) -- (4.2,0) node[right] {$x$};
  \\draw[->] (0,-0.2) -- (0,3.2) node[above] {$y$};
  % Function y = sqrt(x)
  \\draw[blue] plot[samples=100,domain=0:4] (\\x,{sqrt(\\x)});
  \\node[blue] at (3,0.8) {$y=\\sqrt{x}$};
  % A rectangle region
  %\\draw[fill=green!10,draw=green!50!black] (1,0.4) rectangle (1.8,1.2);
\\end{tikzpicture}%
"""

completeGraph = """
\\newcount\\mycount
\\begin{tikzpicture}[transform shape]
  %the multiplication with floats is not possible. Thus I split the loop in two.
  \\foreach \\number in {1,...,8}{
      % Computer angle:
        \\mycount=\\number
        \\advance\\mycount by -1
  \\multiply\\mycount by 45
        \\advance\\mycount by 0
      \\node[draw,circle,inner sep=0.25cm] (N-\\number) at (\\the\\mycount:5.4cm) {};
    }
  \\foreach \\number in {9,...,16}{
      % Computer angle:
        \\mycount=\\number
        \\advance\\mycount by -1
  \\multiply\\mycount by 45
        \\advance\\mycount by 22.5
      \\node[draw,circle,inner sep=0.25cm] (N-\\number) at (\\the\\mycount:5.4cm) {};
    }
  \\foreach \\number in {1,...,15}{
        \\mycount=\\number
        \\advance\\mycount by 1
  \\foreach \\numbera in {\\the\\mycount,...,16}{
    \\path (N-\\number) edge[->,bend right=3] (N-\\numbera)  edge[<-,bend
      left=3] (N-\\numbera);
  }
}
\\end{tikzpicture}
"""

spheres = """
\\begin{tikzpicture}[
    tdplot_main_coords,
    scale=3,
    axis/.style={-stealth},
    addline/.style={very thin}
]

    \\begin{scope}[axis]
        \\draw (0,0,0) -- (1.5,0,0) node[below]{$x$};
        \\draw (0,0,0) -- (0,1.5,0) node[right]{$y$};
        \\draw (0,0,-0.5) -- (0,0,0.7) node[right]{$z$};
    \\end{scope}

    \\def\\r{0.3} % radius of sphere
    \\def\\a{70} % rotation angle

    \\coordinate (A) at (1,0,0);
    \\coordinate (B) at ({cos(\\a)},{sin(\\a)},0);
    \\foreach \\P/\\Ptop/\\Pbottom in {A/Atop/Abottom, B/Btop/Bbottom} {
        \\coordinate (\\Ptop) at ($(\\P)+(0,0,\\r)$);
        \\coordinate (\\Pbottom) at ($(\\P)+(0,0,-\\r)$);
    }

    % rotation angle
    \\fill[red, opacity=0.6] (0.2,0) node[above]{$\\alpha$}
        arc [radius=0.2, start angle=0, end angle=\\a] -- (0,0,0) -- cycle;

    % draw additional line
    \\begin{scope}[addline]
        \\draw (A) circle (\\r);
        \\draw (B) circle (\\r);
        \\foreach \\h in {-\\r,0,\\r}
            \\draw (1,0,\\h) arc [radius=1, start angle=0, end angle=\\a] -- (0,0,\\h) -- cycle;

        \\tdplotsetrotatedcoords{\\a-90}{90}{0}
        \\tdplotdrawarc[tdplot_rotated_coords]{(B)}{\\r}{0}{360}{}{}

        \\tdplotsetrotatedcoords{90}{90}{0}
        \\tdplotdrawarc[tdplot_rotated_coords]{(A)}{\\r}{0}{360}{}{}
    \\end{scope}

    %point and sphere
    \\begin{scope}[tdplot_screen_coords, on background layer]
        \\fill[ball color=lightgray!20!] (A) circle (\\r);
        \\fill[ball color=lightgray!20!] (B) circle (\\r);
        \\foreach \\P in {A,B,Atop,Btop,Abottom,Bbottom}
            \\fill (\\P) circle (0.01);
    \\end{scope}
\\end{tikzpicture}%
"""

lindemayer = """
% \\RequirePackage{luatex85} % Only for LuaLaTeX and standalone class
\\documentclass[varwidth,border=5]{standalone}
\\usepackage{tikz}
\\usetikzlibrary{lindenmayersystems}
\\pgfdeclarelindenmayersystem{square fractal}{%
  \\symbol{S}{\\pgflsystemstep=0.5\\pgflsystemstep}
  \\symbol{A}{\\pgftransformshift%
    {\\pgfqpoint{0.75\\pgflsystemstep}{0.75\\pgflsystemstep}}}
  \\symbol{R}{\\pgftransformrotate{90}}
  \\symbol{Q}{%
    \\pgfpathrectangle{\\pgfqpoint{-0.5\\pgflsystemstep}{-0.5\\pgflsystemstep}}%
    {\\pgfqpoint{\\pgflsystemstep}{\\pgflsystemstep}}%
  }
  \\rule{Q -> [SQ[ASQ][RASQ][RRASQ][RRRASQ]]}
}

\\begin{document}
% Draw the square-fractal L-system for order = 3 only
\\tikz \\fill [l-system={square fractal, step=5cm, axiom=Q, order=3}]%
  lindenmayer system;
\\end{document}
"""