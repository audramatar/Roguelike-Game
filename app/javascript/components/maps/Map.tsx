import * as React from "react"
import Box from '../../models/Box'

export interface MapProps { map: any[]; }

export const Map = (props: MapProps) => {
  const roomStyle = {
    fill: 'green',
    stroke: 'black',
    strokeWidth: '2',
  };

  const wallStyle = {
    fill: 'white',
    stroke: 'black',
    strokeWidth: '2',
  };

  const doorStyle = {
    fill: 'brown',
    stroke: 'black',
    strokeWidth: '2',
  };

  const hallStyle = {
    fill: 'darkblue',
    stroke: 'black',
    strokeWidth: '2',
  };

  let style = {};

  const updateStyle = (box) => {
    if (box == 'room') {
      style = roomStyle;
    } else if (box == 'wall') {
      style = wallStyle;
    } else if (box == 'door') {
      style = doorStyle;
    } else if (box == 'hall') {
      style = hallStyle;
    }
  };

  return (
    <h1>
      <svg width={props.map.length * 50} height={props.map[0].length * 50}>
        { props.map.map((row, index) =>  {
          return (
            row.map((column, index2) => {
              updateStyle(column);
             return( <rect width='50' height='50' x={50 * index} y={50 * index2} style={style} /> )
            }))
          })
        }
      </svg>
    </h1>
  );
};

export default Map
