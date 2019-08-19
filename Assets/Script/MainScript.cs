using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class MainScript : MonoBehaviour
{
    public GameObject Ground;
    // Start is called before the first frame update

    float Disp;
    float Dir;
    void Start()
    {
        Disp = 0;
        Dir = 1;
    }

    float easeInExpo(float t, float b, float c, float d)
    {
        return c * Mathf.Pow(2, 10 * (t / d - 1)) + b;
    }

    // Update is called once per frame
    void Update()
    {
        Ground.GetComponent<Renderer>().material.SetFloat("_Displacement", easeInExpo(Disp, 0, 1, 1));

        Disp += 0.002f * Dir;
        if (Disp <= 0) Dir = 1;
        else if (Disp >= 1) Dir = -1;

    }
}
