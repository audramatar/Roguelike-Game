import * as React from "react"
import Box from '../../models/Box'

export interface MapProps { bounds: any[]; boxes: Box[]; pathPoints: any }

export const Map = (props: MapProps) => {
  return (
    <h1>
      <svg width={props.bounds[0]} height={props.bounds[1]}>
        { props.boxes.map((object) => <rect
                                        key={object.key}
                                        width={object.width}
                                        height={object.height}
                                        x={object.x}
                                        y={object.y} />) }
        <polyline
          points={props.pathPoints}
          stroke="red"
          strokeWidth="3"
          fill="none"
        />
      </svg>
    </h1>
  );
};

export default Map
