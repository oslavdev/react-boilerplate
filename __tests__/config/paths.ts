import { pathHome } from "@/config/paths";

describe("Test paths", () => {
  it("Path Home. Expect to be /", () => {
    expect(pathHome()).toBe("/");
  })
});