## Communication with server:

OK, we received the response {"name":"tikz-request","url":"tikz-request.png"}


POST request to /tikz2png with TikZ content:

```bash
  curl -X POST http://localhost:3000/tikz2png \
    -H "Content-Type: application/json" \
    -d '{
      "name": "tikz-request",
      "content": "\\begin{tikzpicture}[scale=1.0]\n  % Axes\n  \\draw[->] (-0.2,0) -- (4.2,0) node[right] {$x$};\n  \\draw[->] (0,-0.2) -- (0,3.2) node[above] 
  {$y$};\n  % Function y = sqrt(x)\n  \\draw[thick,blue] plot[samples=100,domain=0:4] (\\x,{sqrt(\\x)});\n  \\node[blue] at (3,1.8) {$y=\\sqrt{x}$};\n  % A 
  rectangle region\n  \\draw[fill=green!10,draw=green!50!black] (1,0.4) rectangle (1.8,1.2);\n\\end{tikzpicture}"
    }'

```


```bash
 curl -v -X POST http://localhost:3000/tikz2png \
    -H "Content-Type: application/json" \
    -d '{"name":"circle-triangle","content":"\\begin{tikzpicture}[scale=1.0]\n  % Axes\n  \\draw[->] (-0.2,0) -- (4.2,0) node[right] {$x$};\n  \\draw[->] 
  (0,-0.2) -- (0,3.2) node[above] {$y$};\n  % Function y = sqrt(x)\n  \\draw[thick,blue] plot[samples=100,domain=0:4] (\\x,{sqrt(\\x)});\n  \\node[blue] at 
  (3,1.8) {$y=\\sqrt{x}$};\n  % A rectangle region\n  \\draw[fill=green!10,draw=green!50!black] (1,0.4) rectangle (1.8,1.2);\n\\end{tikzpicture}"}
```