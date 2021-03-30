import React from 'react';
import Home from "@/react/pages/Home";
import { render } from "@testing-library/react";

describe("Home page", () => {
  it("home page expects to match snapshot", () => {
    const HomePageComponent = render(<Home/>);
    expect(HomePageComponent).toMatchSnapshot();
  })
})