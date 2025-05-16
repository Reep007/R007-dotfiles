const char *colorname[] = {

  /* 8 normal colors */
  [0] = "#040408", /* black   */
  [1] = "#4B4A42", /* red     */
  [2] = "#1D639B", /* green   */
  [3] = "#2C6FAC", /* yellow  */
  [4] = "#538AB3", /* blue    */
  [5] = "#2B90E6", /* magenta */
  [6] = "#5DA5EA", /* cyan    */
  [7] = "#cfdfee", /* white   */

  /* 8 bright colors */
  [8]  = "#909ca6",  /* black   */
  [9]  = "#4B4A42",  /* red     */
  [10] = "#1D639B", /* green   */
  [11] = "#2C6FAC", /* yellow  */
  [12] = "#538AB3", /* blue    */
  [13] = "#2B90E6", /* magenta */
  [14] = "#5DA5EA", /* cyan    */
  [15] = "#cfdfee", /* white   */

  /* special colors */
  [256] = "#040408", /* background */
  [257] = "#cfdfee", /* foreground */
  [258] = "#cfdfee",     /* cursor */
};

/* Default colors (colorname index)
 * foreground, background, cursor */
 unsigned int defaultbg = 0;
 unsigned int defaultfg = 257;
 unsigned int defaultcs = 258;
 unsigned int defaultrcs= 258;
