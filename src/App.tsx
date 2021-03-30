import React from 'react'
import { BrowserRouter, Switch, Route } from 'react-router-dom'
import Home from '@/react/pages/Home';

/* Paths */
import * as p from "@/config/paths";

const App: React.FC = () => {
	return (
		<BrowserRouter>
			<Switch>
				<Route exact path={p.pathHome()} component={Home} />
			</Switch>
		</BrowserRouter>
	)
}

export default App
