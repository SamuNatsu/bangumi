export const formatNumber = (x: number, pow: number = 1000): string => {
  if (x < pow) {
    return x.toString();
  } else if (x < Math.pow(pow, 2)) {
    return `${(x / pow).toFixed(1)}k`;
  } else if (x < Math.pow(pow, 3)) {
    return `${(x / Math.pow(pow, 2)).toFixed(1)}m`;
  } else {
    return `${(x / Math.pow(pow, 3)).toFixed(1)}b`;
  }
};

export const splitNumber = (x: number): string => {
  const c = x.toString().split("").reverse();
  const r = [];
  for (let i = 0; i < c.length; i += 3) {
    r.push(
      c
        .slice(i, i + 3)
        .reverse()
        .join(""),
    );
  }
  return r.reverse().join();
};
